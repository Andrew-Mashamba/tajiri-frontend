// lib/maulid/pages/qaswida_library_page.dart
import 'package:flutter/material.dart';
import '../models/maulid_models.dart';
import '../services/maulid_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class QaswidaLibraryPage extends StatefulWidget {
  const QaswidaLibraryPage({super.key});

  @override
  State<QaswidaLibraryPage> createState() => _QaswidaLibraryPageState();
}

class _QaswidaLibraryPageState extends State<QaswidaLibraryPage>
    with SingleTickerProviderStateMixin {
  final _service = MaulidService();
  late TabController _tabCtrl;
  List<QaswidaRecording> _recordings = [];
  List<QaswidaGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getRecordings(),
      _service.getGroups(),
    ]);
    if (mounted) {
      final recResult = results[0] as PaginatedResult<QaswidaRecording>;
      final grpResult = results[1] as PaginatedResult<QaswidaGroup>;
      setState(() {
        _recordings = recResult.items;
        _groups = grpResult.items;
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
        title: const Text('Maktaba ya Qaswida',
            style: TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Qaswida'),
            Tab(text: 'Vikundi'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildRecordingsList(),
                  _buildGroupsList(),
                ],
              ),
      ),
    );
  }

  Widget _buildRecordingsList() {
    if (_recordings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 48, color: _kSecondary),
            SizedBox(height: 12),
            Text('Hakuna qaswida bado',
                style: TextStyle(color: _kSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recordings.length,
      itemBuilder: (context, i) {
        final q = _recordings[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.play_circle_rounded, size: 36),
                color: _kPrimary,
                onPressed: () {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing ${q.title}...'),
                      backgroundColor: _kPrimary,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title,
                        style: const TextStyle(color: _kPrimary,
                            fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(q.groupName,
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(q.durationFormatted,
                      style: const TextStyle(color: _kSecondary, fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  if (q.year != null)
                    Text('${q.year}',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupsList() {
    if (_groups.isEmpty) {
      return const Center(
        child: Text('Hakuna vikundi bado',
            style: TextStyle(color: _kSecondary, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, i) {
        final g = _groups[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.group_rounded,
                    color: _kPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        style: const TextStyle(color: _kPrimary,
                            fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${g.recordingCount} qaswida'
                        '${g.location != null ? ' \u2022 ${g.location}' : ''}',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _kSecondary, size: 20),
            ],
          ),
        );
      },
    );
  }
}
