// lib/tafuta_msikiti/pages/jumuah_finder_page.dart
import 'package:flutter/material.dart';
import '../models/tafuta_msikiti_models.dart';
import '../services/tafuta_msikiti_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class JumuahFinderPage extends StatefulWidget {
  final int userId;
  const JumuahFinderPage({super.key, required this.userId});

  @override
  State<JumuahFinderPage> createState() => _JumuahFinderPageState();
}

class _JumuahFinderPageState extends State<JumuahFinderPage> {
  final _service = TafutaMsikitiService();
  List<Mosque> _mosques = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.searchNearby(
      latitude: -6.7924, longitude: 39.2083,
    );
    if (mounted) {
      setState(() {
        _mosques = result.items
            .where((m) =>
                m.prayerTimes?.jumuahKhutbah != null ||
                m.prayerTimes?.jumuahIqamah != null)
            .toList();
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
        title: const Text('Sala ya Ijumaa',
            style: TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : _mosques.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mosque_rounded,
                            size: 48, color: _kSecondary),
                        SizedBox(height: 12),
                        Text('Hakuna misikiti ya Jumu\'ah',
                            style: TextStyle(
                                color: _kSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mosques.length,
                    itemBuilder: (context, i) {
                      final mosque = _mosques[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mosque.name,
                                style: const TextStyle(color: _kPrimary,
                                    fontSize: 15, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(mosque.address,
                                style: const TextStyle(
                                    color: _kSecondary, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (mosque.prayerTimes?.jumuahKhutbah !=
                                    null) ...[
                                  const Icon(Icons.mic_rounded,
                                      size: 14, color: _kSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Khutbah: ${mosque.prayerTimes!.jumuahKhutbah}',
                                    style: const TextStyle(
                                        color: _kPrimary, fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (mosque.distanceKm != null) ...[
                                  const Icon(Icons.directions_walk_rounded,
                                      size: 14, color: _kSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${mosque.distanceKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        color: _kSecondary, fontSize: 12),
                                  ),
                                ],
                              ],
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
