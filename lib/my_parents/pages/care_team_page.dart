// lib/my_parents/pages/care_team_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);
const Color _kSuccess = Color(0xFF4CAF50);

class CareTeamPage extends StatefulWidget {
  final Parent parent;
  final int userId;

  const CareTeamPage({
    super.key,
    required this.parent,
    required this.userId,
  });

  @override
  State<CareTeamPage> createState() => _CareTeamPageState();
}

class _CareTeamPageState extends State<CareTeamPage> {
  final MyParentsService _service = MyParentsService();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = true;
  bool _isInviting = false;
  bool _isAccepting = false;
  String _selectedRole = 'co_caregiver';
  String? _token;

  List<ParentCaregiverShare> _caregivers = [];
  ParentCaregiverShare? _pendingInvite;
  List<CareTask> _tasks = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final caregiverResult = await _service.listCaregivers(_token!, widget.parent.id);
      final taskResult = await _service.getCareTasks(_token!, widget.parent.id);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (caregiverResult.success) {
          _caregivers = caregiverResult.items
              .where((c) => c.status == 'accepted')
              .toList();
          final pending = caregiverResult.items
              .where((c) =>
                  c.status == 'pending' &&
                  c.ownerUserId == widget.userId)
              .toList();
          _pendingInvite = pending.isNotEmpty ? pending.first : null;
        }
        if (taskResult.success) {
          _tasks = taskResult.items
            ..sort((a, b) {
              // Sort: pending first, then by due date
              if (a.status != b.status) {
                if (a.status == 'completed') return 1;
                if (b.status == 'completed') return -1;
              }
              final aDate = a.dueDate ?? DateTime(2099);
              final bDate = b.dueDate ?? DateTime(2099);
              return aDate.compareTo(bDate);
            });
          // Check for overdue tasks and notify
          _checkOverdueTasks();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw
              ? 'Imeshindikana kupakia data'
              : 'Failed to load data')),
        );
      }
    }
  }

  /// Fire-and-forget: notify for any overdue tasks.
  void _checkOverdueTasks() {
    final sw = _sw;
    final now = DateTime.now();
    for (final task in _tasks) {
      if (task.status != 'completed' &&
          task.dueDate != null &&
          task.dueDate!.isBefore(now)) {
        try {
          ParentsNotificationHelper.scheduleCareTaskOverdue(
            widget.parent.id,
            widget.parent.name,
            task.title,
            sw,
          );
        } catch (_) {}
        // Only notify for the first overdue task to avoid spam
        break;
      }
    }
  }

  Future<void> _inviteCaregiver() async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isInviting = true);

    try {
      final result = await _service.inviteCaregiver(
        token: _token!,
        parentId: widget.parent.id,
        role: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isInviting = false);

      if (result.success && result.data != null) {
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa kutengeneza mwaliko' : 'Failed to create invite'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInviting = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _acceptInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isAccepting = true);

    try {
      final result = await _service.acceptInvite(
        token: _token!,
        inviteCode: code,
      );
      if (!mounted) return;
      setState(() => _isAccepting = false);

      if (result.success) {
        _codeController.clear();
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Umeshirikiana!' : 'Connected successfully!')),
        );
        // Notify care team of new member
        try {
          ParentsNotificationHelper.scheduleCareTeamNewMember(
            widget.parent.id,
            widget.parent.name,
            sw ? 'Mshiriki mpya' : 'New member',
            sw,
          );
        } catch (_) {}
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Msimbo batili' : 'Invalid code'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _revokeCaregiver(ParentCaregiverShare caregiver) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ondoa ufikivu?' : 'Revoke access?'),
        content: Text(sw
            ? 'Mlezi huyu hataweza kuona tena data ya mzazi.'
            : 'This person will no longer see parent data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Ondoa' : 'Revoke',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true || caregiver.id == null) return;

    try {
      final result = await _service.revokeCaregiver(token: _token!, shareId: caregiver.id!);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Ufikivu umeondolewa' : 'Access revoked')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_sw ? 'Msimbo umenakiliwa' : 'Code copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareCode(String code) {
    final sw = _sw;
    SharePlus.instance.share(ShareParams(
      text: sw
          ? 'Jiunge na timu ya utunzaji wa mzazi wangu kwenye TAJIRI! Tumia msimbo: $code'
          : 'Join my parent care team on TAJIRI! Use code: $code',
    ));
  }

  // ─── Task Management ────────────────────────────────────────────

  void _showAddTaskSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int? assignedTo;
    DateTime? dueDate;
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  sw ? 'Ongeza Kazi' : 'Add Task',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 16),
                _TField(controller: titleCtrl, label: sw ? 'Kichwa cha kazi' : 'Task title'),
                const SizedBox(height: 12),
                _TField(controller: descCtrl,
                    label: sw ? 'Maelezo' : 'Description', maxLines: 3),
                const SizedBox(height: 12),
                // Assign to dropdown
                if (_caregivers.isNotEmpty) ...[
                  Text(sw ? 'Mgawie' : 'Assign to',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: assignedTo,
                        isExpanded: true,
                        hint: Text(sw ? 'Chagua mtu' : 'Select person'),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(sw ? 'Hakuna' : 'Unassigned'),
                          ),
                          ..._caregivers.map((c) => DropdownMenuItem<int?>(
                                value: c.caregiverUserId,
                                child: Text(c.caregiverName ?? (sw ? 'Mlezi' : 'Caregiver'),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setSheetState(() => assignedTo = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Due date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => dueDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          dueDate != null
                              ? '${sw ? 'Tarehe ya mwisho: ' : 'Due: '}'
                                '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                              : (sw ? 'Weka tarehe ya mwisho' : 'Set due date'),
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(sw
                              ? 'Tafadhali ingiza kichwa'
                              : 'Please enter a title')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      _saveTask(
                        title: title,
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        assignedTo: assignedTo,
                        dueDate: dueDate,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      titleCtrl.dispose();
      descCtrl.dispose();
    });
  }

  Future<void> _saveTask({
    required String title,
    String? description,
    int? assignedTo,
    DateTime? dueDate,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.addCareTask(
        token: _token!,
        parentId: widget.parent.id,
        title: title,
        description: description,
        assignedTo: assignedTo,
        dueDate: dueDate,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kazi imeongezwa' : 'Task added')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _toggleTaskComplete(CareTask task) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';

    try {
      final result = await _service.updateCareTask(
        token: _token!,
        taskId: task.id,
        status: newStatus,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(newStatus == 'completed'
              ? (sw ? 'Kazi imekamilika!' : 'Task completed!')
              : (sw ? 'Kazi imefunguliwa tena' : 'Task reopened'))),
        );
        // Notify care team when a task is completed
        if (newStatus == 'completed') {
          try {
            ParentsNotificationHelper.scheduleCareTaskCompleted(
              widget.parent.id,
              widget.parent.name,
              task.title,
              sw ? 'Mshiriki wa timu' : 'Team member',
              sw,
            );
          } catch (_) {}
        }
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kusasisha kazi' : 'Failed to update task'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _deleteTask(CareTask task) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa kazi?' : 'Delete task?'),
        content: Text(sw
            ? 'Hatua hii haiwezi kutenduliwa.'
            : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await _service.deleteCareTask(token: _token!, taskId: task.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kazi imefutwa' : 'Task deleted')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kufuta kazi' : 'Failed to delete task'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  String _findCaregiverName(int? userId) {
    if (userId == null) return _sw ? 'Hajagawiwa' : 'Unassigned';
    if (userId == widget.userId) return _sw ? 'Mimi' : 'Me';
    final match = _caregivers.where((c) => c.caregiverUserId == userId).toList();
    if (match.isNotEmpty && match.first.caregiverName != null) {
      return match.first.caregiverName!;
    }
    return _sw ? 'Mlezi' : 'Caregiver';
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Timu ya Utunzaji' : 'Care Team',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Invite section ────────────────────────
                  _buildInviteSection(sw),
                  const SizedBox(height: 24),

                  // ── Connected caregivers ──────────────────
                  _buildCaregiversList(sw),
                  const SizedBox(height: 24),

                  // ── Accept invite section ─────────────────
                  _buildAcceptSection(sw),
                  const SizedBox(height: 24),

                  // ── Task Board ────────────────────────────
                  _buildTaskBoard(sw),
                  const SizedBox(height: 24),

                  // ── Cross-module links ───────────────────
                  _buildCrossModuleLink(
                    icon: Icons.chat_rounded,
                    label: sw
                        ? 'Tuma ujumbe kwa ndugu'
                        : 'Message sibling',
                    onTap: () {
                      try { Navigator.pushNamed(context, '/messages'); } catch (_) {}
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildInviteSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Alika ndugu/mlezi' : 'Invite Sibling/Caregiver',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          sw
              ? 'Shiriki utunzaji wa mzazi na ndugu'
              : 'Coordinate parent care with siblings',
          style: const TextStyle(fontSize: 12, color: _kSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Chagua jukumu' : 'Select role',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const SizedBox(height: 10),
              _RoleOption(
                label: sw ? 'Mlezi Mwenza (upatikanaji kamili)' : 'Co-caregiver (full access)',
                isSelected: _selectedRole == 'co_caregiver',
                onTap: () => setState(() => _selectedRole = 'co_caregiver'),
              ),
              const SizedBox(height: 8),
              _RoleOption(
                label: sw ? 'Mtazamaji (kusoma tu)' : 'Viewer (read only)',
                isSelected: _selectedRole == 'viewer',
                onTap: () => setState(() => _selectedRole = 'viewer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_pendingInvite != null) ...[
          _InviteCodeCard(
            code: _pendingInvite!.inviteCode,
            isSwahili: sw,
            onCopy: () => _copyCode(_pendingInvite!.inviteCode),
            onShare: () => _shareCode(_pendingInvite!.inviteCode),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isInviting ? null : _inviteCaregiver,
              icon: _isInviting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add_rounded, size: 18),
              label: Text(
                sw ? 'Tengeneza msimbo wa mwaliko' : 'Generate invite code',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCaregiversList(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Timu ya utunzaji' : 'Care team members',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        if (_caregivers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 32, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  sw
                      ? 'Bado hakuna wanatimu'
                      : 'No team members yet',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        else
          ..._caregivers.map((c) => _CaregiverTile(
                caregiver: c,
                isSwahili: sw,
                onRevoke: () => _revokeCaregiver(c),
                onMessage: () {
                  if (c.caregiverUserId != null) {
                    try {
                      Navigator.pushNamed(context, '/chat/${c.caregiverUserId}');
                    } catch (_) {}
                  }
                },
              )),
      ],
    );
  }

  Widget _buildAcceptSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          sw ? 'Una msimbo wa mwaliko?' : 'Have an invite code?',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: sw ? 'Weka msimbo hapa' : 'Enter code here',
                  hintStyle: TextStyle(color: _kSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: _kPrimary.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  letterSpacing: 1, color: _kPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isAccepting ? null : _acceptInvite,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          sw ? 'Kubali mwaliko' : 'Accept invite',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBoard(bool sw) {
    final activeTasks = _tasks.where((t) => t.status != 'completed').toList();
    final completedTasks = _tasks.where((t) => t.status == 'completed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sw ? 'Bodi ya Kazi' : 'Task Board',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
            IconButton(
              onPressed: _showAddTaskSheet,
              icon: const Icon(Icons.add_circle_rounded, color: _kPrimary, size: 24),
              tooltip: sw ? 'Ongeza kazi' : 'Add task',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.task_alt_rounded, size: 32, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  sw ? 'Hakuna kazi' : 'No tasks yet',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else ...[
          // Active tasks
          ...activeTasks.map((t) => _buildTaskCard(t, sw)),
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sw ? 'Zilizokamilika' : 'Completed',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary),
            ),
            const SizedBox(height: 8),
            ...completedTasks.take(5).map((t) => _buildTaskCard(t, sw)),
          ],
        ],
      ],
    );
  }

  Widget _buildTaskCard(CareTask task, bool sw) {
    final completed = task.status == 'completed';
    final overdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !completed;

    return GestureDetector(
      onTap: () => _toggleTaskComplete(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: overdue
              ? Border.all(color: _kDanger.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? _kSuccess : Colors.transparent,
                border: Border.all(
                  color: completed ? _kSuccess : _kSecondary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: completed ? _kSecondary : _kPrimary,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        _findCaregiverName(task.assignedTo),
                        style: const TextStyle(fontSize: 10, color: _kSecondary),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${task.dueDate!.day}/${task.dueDate!.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: overdue ? _kDanger : _kSecondary,
                            fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: completed
                    ? _kSuccess.withValues(alpha: 0.1)
                    : overdue
                        ? _kDanger.withValues(alpha: 0.1)
                        : _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                completed
                    ? (sw ? 'Imekamilika' : 'Done')
                    : overdue
                        ? (sw ? 'Imechelewa' : 'Overdue')
                        : (sw ? 'Inaendelea' : 'Active'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: completed
                      ? _kSuccess
                      : overdue
                          ? _kDanger
                          : _kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Delete button
            GestureDetector(
              onTap: () => _deleteTask(task),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: _kDanger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Option ─────────────────────────────────────────────────

class _RoleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? _kPrimary.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _kPrimary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _kPrimary : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invite Code Card ────────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final bool isSwahili;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _InviteCodeCard({
    required this.code,
    required this.isSwahili,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            isSwahili ? 'Msimbo wa mwaliko' : 'Invite code',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Mpe ndugu msimbo huu'
                : 'Give this code to your sibling',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(isSwahili ? 'Nakili' : 'Copy',
                      style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(isSwahili ? 'Shiriki' : 'Share',
                      style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Caregiver Tile ──────────────────────────────────────────────

class _CaregiverTile extends StatelessWidget {
  final ParentCaregiverShare caregiver;
  final bool isSwahili;
  final VoidCallback onRevoke;
  final VoidCallback onMessage;

  const _CaregiverTile({
    required this.caregiver,
    required this.isSwahili,
    required this.onRevoke,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final String roleBadge;
    switch (caregiver.role) {
      case 'viewer':
        roleBadge = isSwahili ? 'Mtazamaji' : 'Viewer';
      case 'sibling':
        roleBadge = isSwahili ? 'Ndugu' : 'Sibling';
      case 'doctor':
        roleBadge = isSwahili ? 'Daktari' : 'Doctor';
      default:
        roleBadge = isSwahili ? 'Mlezi Mwenza' : 'Co-caregiver';
    }
    final name =
        caregiver.caregiverName ?? (isSwahili ? 'Mlezi' : 'Caregiver');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage: caregiver.caregiverPhoto != null
                ? NetworkImage(caregiver.caregiverPhoto!)
                : null,
            child: caregiver.caregiverPhoto == null
                ? const Icon(Icons.person_rounded, color: _kSecondary, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(roleBadge,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: _kSecondary)),
                ),
              ],
            ),
          ),
          // Message button
          IconButton(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_rounded, size: 18, color: _kSecondary),
            tooltip: isSwahili ? 'Tuma ujumbe' : 'Message',
          ),
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: onRevoke,
              style: TextButton.styleFrom(
                foregroundColor: _kDanger,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                isSwahili ? 'Ondoa' : 'Revoke',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Text Field ──────────────────────────────────────────────────

class _TField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? maxLines;

  const _TField({
    required this.controller,
    required this.label,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        filled: true,
        fillColor: _kPrimary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14, color: _kPrimary),
    );
  }
}
