// lib/projects/pages/projects_page.dart
import 'package:flutter/material.dart';
import '../../business/biz_tab_wrapper.dart' show BusinessSectionHeader;
import '../../business/models/business_models.dart' show Business;
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';
import '../widgets/add_project_sheet.dart';
import '../widgets/project_card.dart';
import 'project_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProjectsPage extends StatefulWidget {
  final List<Business> businesses;
  const ProjectsPage({super.key, required this.businesses});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String? _token;
  final Map<int, List<Project>> _projectsByBusiness = {};
  final Map<int, bool> _loadingByBusiness = {};
  final Map<int, String?> _errorByBusiness = {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isAnyLoading => _loadingByBusiness.values.any((v) => v);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null || !mounted) return;
    setState(() {
      for (final biz in widget.businesses) {
        if (biz.id != null) {
          _loadingByBusiness[biz.id!] = true;
          _errorByBusiness[biz.id!] = null;
        }
      }
    });
    await Future.wait(widget.businesses.map((biz) async {
      if (biz.id == null) return;
      try {
        final res = await ProjectService.getProjects(_token!, biz.id!);
        if (!mounted) return;
        setState(() {
          _loadingByBusiness[biz.id!] = false;
          if (res.success) {
            _projectsByBusiness[biz.id!] = res.data;
          } else {
            _errorByBusiness[biz.id!] = res.message;
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingByBusiness[biz.id!] = false;
            _errorByBusiness[biz.id!] = e.toString();
          });
        }
      }
    }));
  }

  void _pickBusiness(void Function(Business) onPicked) {
    final sw = _sw;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              sw ? 'Chagua Biashara' : 'Select Business',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
            const SizedBox(height: 12),
            ...widget.businesses.map((biz) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _kPrimary.withValues(alpha: 0.1),
                    child: Text(
                      biz.name.isNotEmpty ? biz.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: _kPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(biz.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    onPicked(biz);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _openAdd(int businessId) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddProjectSheet(
        token: _token!,
        businessId: businessId,
        onSaved: _load,
      ),
    );
  }

  void _openEdit(Project project, int businessId) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddProjectSheet(
        token: _token!,
        businessId: businessId,
        project: project,
        onSaved: _load,
      ),
    );
  }

  Future<void> _confirmDelete(Project project) async {
    if (_token == null || project.id == null) return;
    final sw = _sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Mradi' : 'Delete Project',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw
            ? 'Futa mradi "${project.title}"?'
            : 'Delete project "${project.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await ProjectService.deleteProject(_token!, project.id!);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Imefutwa' : 'Deleted')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) _load();
  }

  void _openDetail(Project project, int businessId) {
    if (_token == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ProjectDetailPage(
        project: project,
        token: _token!,
        businessId: businessId,
        onChanged: _load,
      ),
    ));
  }

  List<Widget> _buildSections(bool sw) {
    final items = <Widget>[];
    for (int i = 0; i < widget.businesses.length; i++) {
      final biz = widget.businesses[i];
      if (biz.id == null) continue;
      items.add(BusinessSectionHeader(business: biz, showDivider: i > 0));
      final error = _errorByBusiness[biz.id!];
      if (error != null) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            sw ? 'Imeshindikana kupakia' : 'Failed to load',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ));
      } else {
        final projects = _projectsByBusiness[biz.id!] ?? [];
        if (projects.isEmpty) {
          items.add(Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              sw ? 'Hakuna miradi' : 'No projects yet',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ));
        } else {
          for (final p in projects) {
            items.add(ProjectCard(
              project: p,
              isSwahili: sw,
              onTap: () => _openDetail(p, biz.id!),
              onEditTap: () => _openEdit(p, biz.id!),
              onDeleteTap: () => _confirmDelete(p),
            ));
          }
        }
      }
    }
    items.add(const SizedBox(height: 80)); // FAB clearance
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.businesses.length == 1) {
            _openAdd(widget.businesses.first.id!);
          } else {
            _pickBusiness((biz) => _openAdd(biz.id!));
          }
        },
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isAnyLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _buildSections(sw),
              ),
            ),
    );
  }
}
