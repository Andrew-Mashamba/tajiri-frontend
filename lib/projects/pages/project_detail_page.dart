// lib/projects/pages/project_detail_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';
import '../widgets/add_project_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final String token;
  final int businessId;
  final VoidCallback onChanged;

  const ProjectDetailPage({
    super.key,
    required this.project,
    required this.token,
    required this.businessId,
    required this.onChanged,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  bool _dirty = false; // true if any change was made (triggers parent refresh on pop)
  late String _projectTitle; // local copy so AppBar updates after edit

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _projectTitle = widget.project.title;
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || widget.project.id == null) return;
    setState(() { _loading = true; _error = null; });
    final res = await ProjectService.getTasks(widget.token, widget.project.id!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _tasks = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  List<Task> _filteredByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList();

  void _openAddTask() {
    if (widget.project.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddTaskSheet(
        token: widget.token,
        projectId: widget.project.id!,
        businessId: widget.businessId,
        onSaved: () { setState(() => _dirty = true); _load(); },
      ),
    );
  }

  void _openEditTask(Task task) {
    if (widget.project.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddTaskSheet(
        token: widget.token,
        projectId: widget.project.id!,
        businessId: widget.businessId,
        task: task,
        onSaved: () { setState(() => _dirty = true); _load(); },
      ),
    );
  }

  Future<void> _confirmDeleteTask(Task task) async {
    if (task.id == null) return;
    final sw = _sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Kazi' : 'Delete Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw ? 'Futa "${task.title}"?' : 'Delete "${task.title}"?'),
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
    final res = await ProjectService.deleteTask(widget.token, task.id!);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Imefutwa' : 'Deleted')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) { setState(() => _dirty = true); _load(); }
  }

  void _openEditProject() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddProjectSheet(
        token: widget.token,
        businessId: widget.businessId,
        project: widget.project,
        onSaved: () { setState(() { _dirty = true; }); _load(); },
      ),
    );
  }

  Widget _taskList(TaskStatus status) {
    final list = _filteredByStatus(status);
    final sw = _sw;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.grey.shade500)));
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          sw ? 'Hakuna kazi' : 'No tasks',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final t = list[i];
          return GestureDetector(
            onLongPress: () => _confirmDeleteTask(t),
            child: TaskCard(
              task: t,
              isSwahili: sw,
              onTap: () => _openEditTask(t),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: BackButton(
          color: _kPrimary,
          onPressed: () {
            if (_dirty) widget.onChanged();
            Navigator.of(context).pop();
          },
        ),
        title: Text(_projectTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: _kPrimary),
            onPressed: _openEditProject,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Kusubiri' : 'To-Do'),
            Tab(text: sw ? 'Inaendelea' : 'In Progress'),
            Tab(text: sw ? 'Imekamilika' : 'Done'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTask,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _taskList(TaskStatus.todo),
          _taskList(TaskStatus.inProgress),
          _taskList(TaskStatus.done),
        ],
      ),
    );
  }
}
