// lib/dc/pages/dc_projects_page.dart
import 'package:flutter/material.dart';
import '../models/dc_models.dart';
import '../services/dc_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DcProjectsPage extends StatefulWidget {
  final int districtId;
  const DcProjectsPage({super.key, required this.districtId});

  @override
  State<DcProjectsPage> createState() => _DcProjectsPageState();
}

class _DcProjectsPageState extends State<DcProjectsPage> {
  List<DistrictProject> _projects = [];
  bool _loading = true;
  final _service = DcService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getProjects(widget.districtId);
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Miradi ya Wilaya',
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
                    itemBuilder: (_, i) => _buildProject(_projects[i]),
                  ),
                ),
    );
  }

  Widget _buildProject(DistrictProject p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          if (p.funder.isNotEmpty)
            Text('Mfadhili: ${p.funder}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p.progressPercent / 100, backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary), minHeight: 6),
              ),
            ),
            const SizedBox(width: 8),
            Text('${p.progressPercent}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
          ]),
          const SizedBox(height: 8),
          Text('Bajeti: TZS ${_fmt(p.budget)} | ${p.sector}',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
        ],
      ),
    );
  }

  String _fmt(double b) {
    if (b >= 1e9) return '${(b / 1e9).toStringAsFixed(1)}B';
    if (b >= 1e6) return '${(b / 1e6).toStringAsFixed(1)}M';
    return b.toStringAsFixed(0);
  }
}
