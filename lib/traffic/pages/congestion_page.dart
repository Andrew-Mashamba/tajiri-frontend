// lib/traffic/pages/congestion_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/traffic_models.dart';
import '../services/traffic_service.dart';
import '../widgets/congestion_banner.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CongestionPage extends StatefulWidget {
  const CongestionPage({super.key});
  @override
  State<CongestionPage> createState() => _CongestionPageState();
}

class _CongestionPageState extends State<CongestionPage> {
  List<CongestionAlert> _alerts = [];
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
    final r = await TrafficService.getCongestionAlerts();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _alerts = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia msongamano'
                : 'Failed to load congestion data')),
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
        title: Text(_isSwahili ? 'Msongamano' : 'Congestion',
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
              child: _alerts.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 48, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                              _isSwahili
                                  ? 'Barabara ziko sawa'
                                  : 'Roads are clear',
                              style: const TextStyle(
                                  fontSize: 14, color: _kSecondary)),
                        ]),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => CongestionBanner(
                          alert: _alerts[i], isSwahili: _isSwahili),
                    ),
            ),
    );
  }
}
