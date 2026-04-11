// lib/rc/pages/rc_mega_projects_page.dart
import 'package:flutter/material.dart';
import '../models/rc_models.dart';
import '../services/rc_service.dart';
import '../widgets/mega_project_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RcMegaProjectsPage extends StatefulWidget {
  final int regionId;
  const RcMegaProjectsPage({super.key, required this.regionId});

  @override
  State<RcMegaProjectsPage> createState() => _RcMegaProjectsPageState();
}

class _RcMegaProjectsPageState extends State<RcMegaProjectsPage> {
  List<MegaProject> _projects = [];
  bool _loading = true;
  final _service = RcService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getMegaProjects(widget.regionId);
    if (mounted) {
      setState(() {
        _projects = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Miradi Mikubwa',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _projects.isEmpty
              ? const Center(child: Text('Hakuna miradi', style: TextStyle(color: _kSecondary)))
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MegaProjectCard(project: _projects[i]),
                    ),
                  ),
                ),
    );
  }
}
