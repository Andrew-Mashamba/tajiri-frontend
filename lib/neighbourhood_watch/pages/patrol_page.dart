// lib/neighbourhood_watch/pages/patrol_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/neighbourhood_watch_models.dart';
import '../services/neighbourhood_watch_service.dart';
import '../widgets/patrol_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PatrolPage extends StatefulWidget {
  const PatrolPage({super.key});
  @override
  State<PatrolPage> createState() => _PatrolPageState();
}

class _PatrolPageState extends State<PatrolPage> {
  List<PatrolSchedule> _patrols = [];
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
    final r = await NeighbourhoodWatchService.getPatrols();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _patrols = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia doria'
                : 'Failed to load patrols')),
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
        title: Text(_isSwahili ? 'Ratiba ya Doria' : 'Patrol Schedule',
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
              child: _patrols.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(children: [
                          const Icon(Icons.shield_rounded,
                              size: 48, color: _kSecondary),
                          const SizedBox(height: 12),
                          Text(
                            _isSwahili
                                ? 'Hakuna ratiba za doria'
                                : 'No patrol schedules',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                          ),
                        ]),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _patrols.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => PatrolCard(
                        patrol: _patrols[i],
                        isSwahili: _isSwahili,
                        onJoin: () async {
                          final r = await NeighbourhoodWatchService.joinPatrol(
                              _patrols[i].id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(r.success
                                ? (_isSwahili
                                    ? 'Umejiunga!'
                                    : 'Joined!')
                                : (r.message ?? 'Error')),
                          ));
                          _load();
                        },
                      ),
                    ),
            ),
    );
  }
}
