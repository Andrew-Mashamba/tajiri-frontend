// lib/tafuta_msikiti/pages/tafuta_msikiti_home_page.dart
import 'package:flutter/material.dart';
import '../models/tafuta_msikiti_models.dart';
import '../services/tafuta_msikiti_service.dart';
import 'mosque_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class TafutaMsikitiHomePage extends StatefulWidget {
  final int userId;
  const TafutaMsikitiHomePage({super.key, required this.userId});

  @override
  State<TafutaMsikitiHomePage> createState() => _TafutaMsikitiHomePageState();
}

class _TafutaMsikitiHomePageState extends State<TafutaMsikitiHomePage> {
  final _service = TafutaMsikitiService();
  final _searchCtrl = TextEditingController();
  List<Mosque> _mosques = [];
  bool _loading = true;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search({String? query}) async {
    setState(() => _loading = true);
    final result = await _service.searchNearby(
      latitude: -6.7924, longitude: 39.2083,
      query: query,
    );
    if (mounted) {
      setState(() {
        _mosques = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map/List toggle
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded,
                  color: _kPrimary),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
          ),
        ),
            // ─── Search Bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (q) => _search(query: q),
                decoration: InputDecoration(
                  hintText: 'Tafuta msikiti...',
                  hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _kSecondary, size: 20),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
            ),

            // ─── Content ──────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary))
                  : _showMap
                      ? _buildMapView()
                      : _buildListView(),
            ),
          ],
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_rounded, size: 64, color: _kSecondary),
            SizedBox(height: 12),
            Text('Ramani ya Misikiti',
                style: TextStyle(color: _kPrimary, fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Misikiti karibu nawe',
                style: TextStyle(color: _kSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_mosques.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mosque_rounded, size: 48, color: _kSecondary),
            SizedBox(height: 12),
            Text('Hakuna misikiti ilipatikana',
                style: TextStyle(color: _kSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _mosques.length,
      itemBuilder: (context, i) {
        final mosque = _mosques[i];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => MosqueDetailPage(mosqueId: mosque.id))),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.mosque_rounded,
                      color: _kPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mosque.name,
                          style: const TextStyle(color: _kPrimary,
                              fontSize: 15, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(mosque.address,
                          style: const TextStyle(
                              color: _kSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (mosque.distanceKm != null)
                        Text('${mosque.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: _kSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (mosque.rating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 2),
                          Text(mosque.rating!.toStringAsFixed(1),
                              style: const TextStyle(color: _kPrimary,
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    const Icon(Icons.chevron_right_rounded,
                        color: _kSecondary, size: 20),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
