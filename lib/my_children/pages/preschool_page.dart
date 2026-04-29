// lib/my_children/pages/preschool_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PreschoolPage extends StatefulWidget {
  final Child child;

  const PreschoolPage({super.key, required this.child});

  @override
  State<PreschoolPage> createState() => _PreschoolPageState();
}

class _PreschoolPageState extends State<PreschoolPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  // Attendance: key = 'yyyy-MM-dd', value = 'attended' | 'absent'
  Map<String, String> _attendance = {};

  // Fee tracking: key = month index (1-12), value = {amount, paid, datePaid}
  Map<int, _FeeRecord> _fees = {};

  // Daily reports: key = 'yyyy-MM-dd', value = note text
  Map<String, String> _dailyReports = {};

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

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

  String get _prefKey => 'preschool_${widget.child.id}';

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && mounted) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _attendance = Map<String, String>.from(data['attendance'] ?? {});
          _dailyReports = Map<String, String>.from(data['reports'] ?? {});
          final feesRaw = data['fees'] as Map<String, dynamic>? ?? {};
          _fees = feesRaw.map((k, v) =>
              MapEntry(int.parse(k), _FeeRecord.fromMap(v as Map<String, dynamic>)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw ? 'Hitilafu kupakia data' : 'Failed to load data')),
        );
      }
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'attendance': _attendance,
        'reports': _dailyReports,
        'fees': _fees.map((k, v) => MapEntry(k.toString(), v.toMap())),
      };
      await prefs.setString(_prefKey, jsonEncode(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Shule ya Awali' : 'Preschool',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Mahudhurio' : 'Attendance'),
            Tab(text: sw ? 'Ada' : 'Fees'),
            Tab(text: sw ? 'Ripoti' : 'Reports'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAttendanceTab(sw),
            _buildFeesTab(sw),
            _buildReportsTab(sw),
          ],
        ),
      ),
    );
  }

  // ─── Attendance Tab ──────────────────────────────────────────

  Widget _buildAttendanceTab(bool sw) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon

    final dayNames = sw
        ? ['Jpt', 'Jtt', 'Jnn', 'Alh', 'Ijm', 'Jms', 'Jpli']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final monthNames = sw
        ? ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
           'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba']
        : ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December'];

    final attended = _attendance.entries
        .where((e) => e.key.startsWith('$year-${month.toString().padLeft(2, '0')}') && e.value == 'attended')
        .length;
    final absent = _attendance.entries
        .where((e) => e.key.startsWith('$year-${month.toString().padLeft(2, '0')}') && e.value == 'absent')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month navigator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: _kPrimary),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(year, month - 1);
                });
              },
            ),
            Text(
              '${monthNames[month - 1]} $year',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: _kPrimary),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(year, month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('$attended',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
                    Text(sw ? 'Alihudhuria' : 'Attended',
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$absent',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
                    Text(sw ? 'Hakuhudhuria' : 'Absent',
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Day headers
        Row(
          children: dayNames
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kSecondary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),

        // Calendar grid
        ..._buildCalendarRows(year, month, daysInMonth, firstWeekday),
        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(const Color(0xFF1A1A1A), sw ? 'Alihudhuria' : 'Attended'),
            const SizedBox(width: 20),
            _legendDot(Colors.grey.shade400, sw ? 'Hakuhudhuria' : 'Absent'),
          ],
        ),
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
          icon: Icons.chat_rounded,
          label: sw
              ? 'Uliza Shangazi kuhusu utayari wa shule ya awali'
              : 'Ask Shangazi about preschool readiness',
          onTap: () => Navigator.pushNamed(context, '/chat/0'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }

  List<Widget> _buildCalendarRows(int year, int month, int daysInMonth, int firstWeekday) {
    final rows = <Widget>[];
    final offset = firstWeekday - 1; // 0-based offset for Monday start
    int day = 1;

    for (int row = 0; row < 6 && day <= daysInMonth; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < offset || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 48)));
        } else {
          final d = day;
          final key = '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
          final status = _attendance[key];
          cells.add(Expanded(
            child: GestureDetector(
              onTap: () => _toggleAttendance(key),
              child: Container(
                height: 48,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: status == 'attended'
                      ? _kPrimary
                      : status == 'absent'
                          ? Colors.grey.shade300
                          : _kCardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: status == 'attended' ? Colors.white : _kPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ));
          day++;
        }
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }

  void _toggleAttendance(String key) {
    setState(() {
      final current = _attendance[key];
      if (current == null) {
        _attendance[key] = 'attended';
      } else if (current == 'attended') {
        _attendance[key] = 'absent';
      } else {
        _attendance.remove(key);
      }
    });
    _saveData();
  }

  // ─── Fees Tab ─────────────────────────────────────────────────

  Widget _buildFeesTab(bool sw) {
    final monthNames = sw
        ? ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
           'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba']
        : ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final fee = _fees[month];
        final isPaid = fee?.paid ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isPaid ? _kPrimary.withValues(alpha: 0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.payment_rounded,
                  color: isPaid ? _kPrimary : _kSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthNames[index],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (fee?.amount != null && fee!.amount > 0)
                      Text(
                        'TZS ${fee.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                  ],
                ),
              ),
              Text(
                isPaid
                    ? (sw ? 'Imelipwa' : 'Paid')
                    : (sw ? 'Haijalipwa' : 'Unpaid'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPaid ? _kPrimary : _kSecondary,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48, height: 48,
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18, color: _kSecondary),
                  onPressed: () => _showFeeDialog(month, monthNames[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFeeDialog(int month, String monthName) async {
    final sw = _sw;
    final existing = _fees[month];
    final amountCtrl = TextEditingController(
        text: existing?.amount != null ? existing!.amount.toStringAsFixed(0) : '');
    bool paid = existing?.paid ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: _kCardBg,
            title: Text(monthName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(sw ? 'Imelipwa' : 'Paid',
                      style: const TextStyle(fontSize: 14, color: _kPrimary)),
                  value: paid,
                  activeThumbColor: _kPrimary,
                  onChanged: (v) => setDialogState(() => paid = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(sw ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(color: _kSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(sw ? 'Hifadhi' : 'Save',
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        });
      },
    );

    if (result == true && mounted) {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      setState(() {
        _fees[month] = _FeeRecord(
          amount: amount,
          paid: paid,
          datePaid: paid ? DateTime.now().toIso8601String() : null,
        );
      });
      _saveData();

      // Record expenditure if marked as paid
      if (paid && amount > 0) {
        final token = LocalStorageService.instanceSync?.getAuthToken();
        if (token != null) {
          try {
            await ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'ada_shule',
              description: 'Preschool fee - ${widget.child.name}',
              sourceModule: 'my_children',
            );
          } catch (_) {}
        }

        // Sync term dates to calendar (fire-and-forget)
        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        _syncToCalendar(
          'Preschool fee paid - ${widget.child.name} (${monthNames[month - 1]})',
          DateTime(DateTime.now().year, month, 1),
        );
      }
    }
    amountCtrl.dispose();
  }

  void _syncToCalendar(String title, DateTime date) {
    try {
      CalendarService().createEvent(CalendarEvent(
        id: 0,
        userId: widget.child.userId,
        title: title,
        date: date,
        isAllDay: true,
        source: EventSource.family,
      ));
    } catch (_) {}
  }

  // ─── Reports Tab ──────────────────────────────────────────────

  Widget _buildReportsTab(bool sw) {
    final today = DateTime.now();
    final last30 = List.generate(30, (i) => today.subtract(Duration(days: i)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: last30.length,
      itemBuilder: (context, index) {
        final date = last30[index];
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final report = _dailyReports[key];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _editReport(key, date),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${date.day}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                      Text('${date.month}/${date.year % 100}',
                          style: const TextStyle(fontSize: 9, color: _kSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report ?? (sw ? 'Bonyeza kuongeza maelezo' : 'Tap to add notes'),
                    style: TextStyle(
                      fontSize: 13,
                      color: report != null ? _kPrimary : _kSecondary,
                      fontStyle: report != null ? FontStyle.normal : FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.edit_rounded, size: 16, color: _kSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editReport(String key, DateTime date) async {
    final sw = _sw;
    final ctrl = TextEditingController(text: _dailyReports[key] ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          title: Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: TextField(
            controller: ctrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: sw ? 'Maelezo ya siku...' : 'Daily notes...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(sw ? 'Ghairi' : 'Cancel',
                  style: const TextStyle(color: _kSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(sw ? 'Hifadhi' : 'Save',
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        if (result.isEmpty) {
          _dailyReports.remove(key);
        } else {
          _dailyReports[key] = result;
        }
      });
      _saveData();
    }
    ctrl.dispose();
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
}

class _FeeRecord {
  final double amount;
  final bool paid;
  final String? datePaid;

  const _FeeRecord({required this.amount, required this.paid, this.datePaid});

  factory _FeeRecord.fromMap(Map<String, dynamic> map) {
    return _FeeRecord(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paid: map['paid'] == true,
      datePaid: map['datePaid'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'paid': paid,
        if (datePaid != null) 'datePaid': datePaid,
      };
}
