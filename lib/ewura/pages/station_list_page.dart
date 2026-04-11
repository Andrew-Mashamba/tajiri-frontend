// lib/ewura/pages/station_list_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ewura_models.dart';
import '../services/ewura_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class StationListPage extends StatefulWidget {
  const StationListPage({super.key});
  @override
  State<StationListPage> createState() => _StationListPageState();
}

class _StationListPageState extends State<StationListPage> {
  List<FuelStation> _stations = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await EwuraService.getStations();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _stations = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia vituo'
                : 'Failed to load stations')),
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
        title: Text(_isSwahili ? 'Vituo vya Mafuta' : 'Fuel Stations',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: _stations.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Text(
                            _isSwahili ? 'Hakuna vituo' : 'No stations found',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary)),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = _stations[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.local_gas_station_rounded,
                                    color: _kPrimary,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text('${s.brand} - ${s.region}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _kSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Row(
                                      children: [
                                        if (s.hasShop)
                                          _Tag(
                                              _isSwahili ? 'Duka' : 'Shop'),
                                        if (s.hasCarWash)
                                          _Tag(_isSwahili
                                              ? 'Kuosha'
                                              : 'Car Wash'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (s.distance != null)
                                Text(
                                  '${s.distance!.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500),
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

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 9, color: Color(0xFF1A1A1A))),
    );
  }
}
