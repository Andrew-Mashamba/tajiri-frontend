// lib/barozi_wangu/pages/projects_page.dart
import 'package:flutter/material.dart';
import '../models/barozi_wangu_models.dart';
import '../services/barozi_wangu_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ProjectsPage extends StatefulWidget {
  final int wardId;
  const ProjectsPage({super.key, required this.wardId});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<DevelopmentProject> _projects = [];
  bool _loading = true;

  final _service = BaroziWanguService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getProjects(widget.wardId);
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
        title: const Text(
          'Miradi ya Maendeleo',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _projects.isEmpty
              ? const Center(
                  child: Text(
                    'Hakuna miradi kwa sasa',
                    style: TextStyle(color: _kSecondary, fontSize: 14),
                  ),
                )
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

  Widget _buildProject(DevelopmentProject project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 14, color: _kSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  project.contractor.isNotEmpty
                      ? project.contractor
                      : 'Mkandarasi haijulikani',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Progress bar ──
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progressPercent / 100,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${project.progressPercent}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bajeti: TZS ${_fmtBudget(project.budget)}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              Text(
                project.sector,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtBudget(double b) {
    if (b >= 1000000000) return '${(b / 1000000000).toStringAsFixed(1)}B';
    if (b >= 1000000) return '${(b / 1000000).toStringAsFixed(1)}M';
    if (b >= 1000) return '${(b / 1000).toStringAsFixed(0)}K';
    return b.toStringAsFixed(0);
  }
}
