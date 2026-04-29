// lib/my_children/pages/activity_manager_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ActivityManagerPage extends StatefulWidget {
  final Child child;
  final int userId;

  const ActivityManagerPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<ActivityManagerPage> createState() => _ActivityManagerPageState();
}

class _ActivityManagerPageState extends State<ActivityManagerPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<ActivityEnrollment> _activities = [];
  String? _token;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getActivities(_token!, widget.child.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _activities = result.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana kupakia' : 'Failed to load'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final totalMonthlyCost = _activities
        .where((a) =>
            a.feeFrequency == 'monthly' || a.feeFrequency == null)
        .fold<double>(0, (sum, a) => sum + a.feeAmount);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Shughuli' : 'Activities',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showEnrollDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadActivities,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Monthly cost card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_rounded,
                              size: 28, color: _kPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sw
                                      ? 'Gharama za Kila Mwezi'
                                      : 'Monthly Activity Costs',
                                  style: const TextStyle(
                                      fontSize: 13, color: _kSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TZS ${totalMonthlyCost.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_activities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            sw
                                ? 'Hakuna shughuli bado'
                                : 'No activities yet',
                            style: const TextStyle(
                                fontSize: 15, color: _kSecondary),
                          ),
                        ),
                      )
                    else
                      ..._activities.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildActivityCard(sw, a),
                          )),

                    // ─── Cross-module links ──────────────
                    const SizedBox(height: 20),
                    Text(
                      sw ? 'Viunganishi' : 'Related',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCrossModuleLink(
                      icon: Icons.calendar_month_rounded,
                      label: sw
                          ? 'Weka ratiba za shughuli kwenye kalenda'
                          : 'Sync activity schedules to calendar',
                      onTap: () => _syncActivitiesToCalendar(),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.shopping_bag_rounded,
                      label: sw
                          ? 'Nunua vifaa vya michezo'
                          : 'Shop sports equipment',
                      onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  void _syncActivitiesToCalendar() {
    try {
      final calService = CalendarService();
      for (final a in _activities) {
        // Sync start date of each activity to calendar
        final date = a.startDate ?? DateTime.now();
        calService.createEvent(CalendarEvent(
          id: 0,
          userId: widget.userId,
          title: '${a.activityName} - ${widget.child.name}',
          date: date,
          isAllDay: true,
          notes: a.schedule,
          source: EventSource.family,
        ));
      }
      if (mounted) {
        final sw = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Imewekwa kwenye kalenda' : 'Synced to calendar')),
        );
      }
    } catch (_) {}
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildActivityCard(bool sw, ActivityEnrollment activity) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteActivity(activity.id, activity.activityName),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.activityName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activity.categoryLabelLocalized(isSwahili: sw),
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activity.schedule != null && activity.schedule!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activity.schedule!,
                    style:
                        const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (activity.feeAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments_rounded,
                    size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(
                  'TZS ${activity.feeAmount.toStringAsFixed(0)}'
                  '${activity.feeFrequency != null ? " / ${activity.feeFrequency}" : ""}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _confirmDeleteActivity(int id, String label) {
    final sw = _sw;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$label"?' : 'Delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_token == null) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final result =
                    await _service.deleteActivity(_token!, id);
                if (!mounted) return;
                if (result.success) {
                  _loadActivities();
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        sw ? 'Shughuli imefutwa' : 'Activity deleted'),
                  ));
                } else {
                  messenger.showSnackBar(SnackBar(
                      content: Text(result.message ?? 'Error')));
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(
                      sw ? 'Imeshindikana kufuta' : 'Failed to delete'),
                ));
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEnrollDialog() {
    final sw = _sw;
    final nameCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    String category = 'sports';
    String feeFrequency = 'monthly';
    DateTime startDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Jiandikishe Shughuli' : 'Enroll Activity',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: sw ? 'Jina la Shughuli' : 'Activity Name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: sw ? 'Aina' : 'Category',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'sports',
                          child:
                              Text(sw ? 'Michezo' : 'Sports')),
                      DropdownMenuItem(
                          value: 'arts',
                          child: Text(sw ? 'Sanaa' : 'Arts')),
                      DropdownMenuItem(
                          value: 'academic',
                          child: Text(sw ? 'Elimu' : 'Academic')),
                      DropdownMenuItem(
                          value: 'religious',
                          child: Text(sw ? 'Dini' : 'Religious')),
                      DropdownMenuItem(
                          value: 'other',
                          child: Text(sw ? 'Nyingine' : 'Other')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scheduleCtrl,
                    decoration: InputDecoration(
                      labelText:
                          sw ? 'Ratiba (mf. Jmt 15:00)' : 'Schedule (e.g. Mon 3PM)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: sw ? 'Ada (TZS)' : 'Fee (TZS)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: feeFrequency,
                          decoration: InputDecoration(
                            labelText: sw ? 'Mzunguko' : 'Frequency',
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'monthly',
                                child: Text(
                                    sw ? 'Kila mwezi' : 'Monthly')),
                            DropdownMenuItem(
                                value: 'termly',
                                child: Text(
                                    sw ? 'Kila muhula' : 'Termly')),
                            DropdownMenuItem(
                                value: 'yearly',
                                child: Text(
                                    sw ? 'Kila mwaka' : 'Yearly')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => feeFrequency = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheetState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 8),
                          Text(
                            '${sw ? "Tarehe ya kuanza" : "Start date"}: '
                            '${startDate.day}/${startDate.month}/${startDate.year}',
                            style: const TextStyle(
                                fontSize: 14, color: _kPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        _submitEnroll(
                          ctx,
                          name,
                          category,
                          scheduleCtrl.text.trim(),
                          double.tryParse(feeCtrl.text.trim()) ?? 0,
                          feeFrequency,
                          startDate,
                        );
                      },
                      child: Text(sw ? 'Jiandikishe' : 'Enroll'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _submitEnroll(
    BuildContext ctx,
    String name,
    String category,
    String schedule,
    double fee,
    String feeFreq,
    DateTime startDate,
  ) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(ctx).pop();

    try {
      final result = await _service.enrollActivity(
        token: _token!,
        childId: widget.child.id,
        activityName: name,
        category: category,
        schedule: schedule.isNotEmpty ? schedule : null,
        feeAmount: fee,
        feeFrequency: feeFreq,
        startDate: startDate,
      );
      if (!mounted) return;
      if (result.success) {
        _loadActivities();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                _sw ? 'Shughuli imeongezwa' : 'Activity enrolled'),
          ),
        );
        // Fire-and-forget: schedule fee due notification
        if (fee > 0) {
          ChildrenNotificationHelper.scheduleFeeDueAlert(
            widget.child.id,
            widget.child.name,
            name,
            fee,
            isSwahili: _sw,
          ).catchError((_) {});
        }
        // Fire-and-forget: report activity fee as parent expenditure
        if (fee > 0 && _token != null) {
          ExpenditureService.recordExpenditure(
            token: _token!,
            amount: fee,
            category: 'watoto',
            description: 'Child expense: ${widget.child.name} — activity fee: $name',
            referenceId: 'child_expense_${widget.child.id}_${DateTime.now().millisecondsSinceEpoch}',
            sourceModule: 'my_children',
          ).catchError((_) => null);
        }
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana kuhifadhi' : 'Failed to save'),
        ),
      );
    }
  }
}
