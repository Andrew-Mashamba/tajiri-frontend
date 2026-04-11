// lib/my_class/pages/class_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/my_class_models.dart';
import '../services/my_class_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ClassDetailPage extends StatefulWidget {
  final int classId;
  final int userId;
  const ClassDetailPage({super.key, required this.classId, required this.userId});
  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> with SingleTickerProviderStateMixin {
  final MyClassService _service = MyClassService();
  late TabController _tabController;
  List<ClassMember> _members = [];
  List<ClassAnnouncement> _announcements = [];
  List<LecturerProfile> _lecturers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getMembers(widget.classId),
      _service.getAnnouncements(widget.classId),
      _service.getLecturers(widget.classId),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final mRes = results[0] as ClassListResult<ClassMember>;
        final aRes = results[1] as ClassListResult<ClassAnnouncement>;
        final lRes = results[2] as ClassListResult<LecturerProfile>;
        if (mRes.success) _members = mRes.items;
        if (aRes.success) _announcements = aRes.items;
        if (lRes.success) _lecturers = lRes.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Text('Darasa / Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Matangazo / Announcements'),
            Tab(text: 'Wanachuo / Students'),
            Tab(text: 'Wahadhiri / Lecturers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(controller: _tabController, children: [
              _buildAnnouncements(),
              _buildMembers(),
              _buildLecturers(),
            ]),
    );
  }

  Widget _buildAnnouncements() {
    if (_announcements.isEmpty) {
      return const Center(child: Text('Hakuna matangazo / No announcements', style: TextStyle(color: _kSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (_, i) {
        final a = _announcements[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (a.isPinned) const Icon(Icons.push_pin_rounded, size: 14, color: _kPrimary),
              if (a.isPinned) const SizedBox(width: 4),
              Expanded(child: Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Text(a.body, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(a.authorName, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ]),
        );
      },
    );
  }

  Widget _buildMembers() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (_, i) {
        final m = _members[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _kPrimary.withValues(alpha: 0.1),
            backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
            child: m.avatarUrl == null ? Text(m.name.isNotEmpty ? m.name[0] : '?', style: const TextStyle(color: _kPrimary)) : null,
          ),
          title: Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(m.role.displayName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          trailing: m.phone != null
              ? IconButton(icon: const Icon(Icons.phone_rounded, size: 20), onPressed: () {
                  Clipboard.setData(ClipboardData(text: m.phone!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nambari imenakiliwa / Number copied')));
                })
              : null,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _buildLecturers() {
    if (_lecturers.isEmpty) {
      return const Center(child: Text('Hakuna wahadhiri / No lecturers', style: TextStyle(color: _kSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lecturers.length,
      itemBuilder: (_, i) {
        final l = _lecturers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (l.department != null) Text(l.department!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
            if (l.officeLocation != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(l.officeLocation!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ]),
            ],
            if (l.officeHours != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(l.officeHours!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ]),
            ],
          ]),
        );
      },
    );
  }
}
