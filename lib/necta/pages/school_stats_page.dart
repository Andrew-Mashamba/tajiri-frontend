// lib/necta/pages/school_stats_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/necta_models.dart';
import '../services/necta_service.dart';
import '../widgets/school_stats_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SchoolStatsPage extends StatefulWidget {
  const SchoolStatsPage({super.key});
  @override
  State<SchoolStatsPage> createState() => _SchoolStatsPageState();
}

class _SchoolStatsPageState extends State<SchoolStatsPage> {
  List<SchoolStats> _stats = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  String? _region;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await NectaService.getSchoolStats(region: _region);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _stats = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia takwimu'
                : 'Failed to load statistics')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            _isSwahili ? 'Takwimu za Shule' : 'School Statistics',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String?>(
              value: _region,
              decoration: InputDecoration(
                hintText: _isSwahili ? 'Chagua mkoa' : 'Select region',
                hintStyle:
                    const TextStyle(color: _kSecondary, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_isSwahili ? 'Mikoa Yote' : 'All Regions')),
                ...['Dar es Salaam', 'Dodoma', 'Arusha', 'Mwanza',
                    'Mbeya', 'Tanga', 'Morogoro', 'Kilimanjaro']
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r))),
              ],
              onChanged: (v) {
                setState(() => _region = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _kPrimary,
                    child: _stats.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _isSwahili
                                    ? 'Hakuna takwimu'
                                    : 'No statistics found',
                                style: const TextStyle(
                                    fontSize: 14, color: _kSecondary),
                              ),
                            ),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _stats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => SchoolStatsCard(
                                stats: _stats[i], isSwahili: _isSwahili),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
