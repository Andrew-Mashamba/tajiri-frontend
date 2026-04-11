// lib/police/pages/station_finder_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/police_models.dart';
import '../services/police_service.dart';
import '../widgets/station_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class StationFinderPage extends StatefulWidget {
  const StationFinderPage({super.key});
  @override
  State<StationFinderPage> createState() => _StationFinderPageState();
}

class _StationFinderPageState extends State<StationFinderPage> {
  List<PoliceStation> _stations = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadStations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    final result = await PoliceService.getStations();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _stations = result.items;
    });
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia vituo'
                : 'Failed to load stations')),
      ));
    }
  }

  List<PoliceStation> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _stations;
    return _stations
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.regionName.toLowerCase().contains(q) ||
            s.districtName.toLowerCase().contains(q))
        .toList();
  }

  void _callStation(PoliceStation station) async {
    if (station.phone == null) return;
    final uri = Uri(scheme: 'tel', path: station.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Vituo vya Polisi' : 'Police Stations',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _isSwahili ? 'Tafuta kituo...' : 'Search station...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kSecondary, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : RefreshIndicator(
                    onRefresh: _loadStations,
                    color: _kPrimary,
                    child: _filtered.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _isSwahili
                                    ? 'Hakuna vituo vilivopatikana'
                                    : 'No stations found',
                                style: const TextStyle(
                                    color: _kSecondary, fontSize: 14),
                              ),
                            ),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final s = _filtered[i];
                              return StationCard(
                                station: s,
                                isSwahili: _isSwahili,
                                onCall: () => _callStation(s),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
