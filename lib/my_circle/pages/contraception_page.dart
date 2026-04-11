// lib/my_circle/pages/contraception_page.dart
import 'package:flutter/material.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../models/my_circle_models.dart';
import '../services/my_circle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ContraceptionPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const ContraceptionPage({super.key, required this.userId, this.isSwahili = false});
  @override
  State<ContraceptionPage> createState() => _ContraceptionPageState();
}

class _ContraceptionPageState extends State<ContraceptionPage> {
  final MyCircleService _service = MyCircleService();
  List<ContraceptionReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final result = await _service.getContraceptionReminders(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _reminders = result.items;
      });
    }
  }

  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddReminderSheet(
        userId: widget.userId,
        service: _service,
        isSwahili: widget.isSwahili,
        onSaved: () {
          Navigator.pop(ctx);
          _loadReminders();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(widget.isSwahili ? 'Uzazi wa Mpango' : 'Contraception', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _kPrimary),
            onPressed: _showAddReminderSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadReminders,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 20, color: _kSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isSwahili
                                ? 'Fuatilia uzazi wa mpango wako na upate vikumbusho kwa wakati.'
                                : 'Track your contraception and get timely reminders.',
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_reminders.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.shield_rounded, size: 48, color: _kPrimary.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(widget.isSwahili ? 'Hakuna vikumbusho' : 'No reminders', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                          const SizedBox(height: 4),
                          Text(widget.isSwahili ? 'Ongeza njia yako ya uzazi wa mpango' : 'Add your contraception method', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showAddReminderSheet,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(widget.isSwahili ? 'Ongeza' : 'Add'),
                            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Active reminders
                    Text(widget.isSwahili ? 'Vikumbusho Vyako' : 'Your Reminders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 10),
                    ..._reminders.map((r) => _ReminderCard(reminder: r, isSwahili: widget.isSwahili)),
                  ],

                  const SizedBox(height: 24),

                  // Common contraception types info
                  Text(widget.isSwahili ? 'Njia za Uzazi wa Mpango' : 'Contraception Methods', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 10),
                  ...ContraceptionType.values.map((type) => _ContraceptionInfoTile(type: type, isSwahili: widget.isSwahili)),
                  const SizedBox(height: 20),

                  // Pharmacy link
                  Material(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PharmacyModule(userId: widget.userId),
                        ));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.local_pharmacy_rounded, color: _kPrimary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.isSwahili ? 'Agiza Dawa' : 'Order Medicine', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                                  Text(widget.isSwahili ? 'Nunua dawa za uzazi wa mpango' : 'Buy contraception medication', style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: _kSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─── Reminder Card ─────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final ContraceptionReminder reminder;
  final bool isSwahili;
  const _ReminderCard({required this.reminder, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = reminder.isOverdue
        ? const Color(0xFFEF5350)
        : reminder.isDueToday
            ? const Color(0xFFFF9800)
            : const Color(0xFF66BB6A);

    String statusText;
    if (reminder.isDueToday) {
      statusText = isSwahili ? 'Leo!' : 'Today!';
    } else if (reminder.isOverdue) {
      statusText = isSwahili ? 'Imepitwa siku ${-reminder.daysUntilDue}' : 'Overdue by ${-reminder.daysUntilDue} days';
    } else if (reminder.daysUntilDue >= 0) {
      statusText = isSwahili ? 'Siku ${reminder.daysUntilDue} zimebaki' : '${reminder.daysUntilDue} days remaining';
    } else {
      statusText = '--';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(reminder.type.icon, size: 22, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.type.displayName(isSwahili), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                if (reminder.nextDueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    isSwahili
                        ? 'Tarehe ijayo: ${reminder.nextDueDate!.day}/${reminder.nextDueDate!.month}/${reminder.nextDueDate!.year}'
                        : 'Next due: ${reminder.nextDueDate!.day}/${reminder.nextDueDate!.month}/${reminder.nextDueDate!.year}',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (reminder.type == ContraceptionType.injectable) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Depo-Provera: kila siku 84',
                    style: TextStyle(fontSize: 10, color: _kSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contraception Info Tile ───────────────────────────────────

class _ContraceptionInfoTile extends StatelessWidget {
  final ContraceptionType type;
  final bool isSwahili;
  const _ContraceptionInfoTile({required this.type, this.isSwahili = false});

  String get _description {
    switch (type) {
      case ContraceptionType.pill: return isSwahili ? 'Vidonge vya kuzuia mimba — kila siku' : 'Birth control pills — daily';
      case ContraceptionType.injectable: return isSwahili ? 'Sindano ya Depo-Provera — kila miezi 3 (siku 84)' : 'Depo-Provera injection — every 3 months (84 days)';
      case ContraceptionType.iud: return isSwahili ? 'Kitanzi kinachowekwa ndani ya mfuko wa uzazi — hadi miaka 5' : 'IUD placed in the uterus — up to 5 years';
      case ContraceptionType.condom: return isSwahili ? 'Kondomu — kila wakati wa kujamiiana' : 'Condom — every time during intercourse';
      case ContraceptionType.natural: return isSwahili ? 'Njia ya asili — kufuatilia siku za rutuba' : 'Natural method — tracking fertile days';
      case ContraceptionType.implant: return isSwahili ? 'Kipandikizi cha mkono — hadi miaka 3' : 'Arm implant — up to 3 years';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(type.icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.displayName(isSwahili), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_description, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (type.defaultIntervalDays > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
              child: Text(
                type.defaultIntervalDays == 1
                    ? (isSwahili ? 'Kila siku' : 'Daily')
                    : (isSwahili ? 'Siku ${type.defaultIntervalDays}' : '${type.defaultIntervalDays} days'),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Add Reminder Bottom Sheet ─────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  final int userId;
  final MyCircleService service;
  final VoidCallback onSaved;
  final bool isSwahili;
  const _AddReminderSheet({required this.userId, required this.service, required this.onSaved, this.isSwahili = false});
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  ContraceptionType _selectedType = ContraceptionType.pill;
  DateTime _startDate = DateTime.now();
  late int _intervalDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _intervalDays = _selectedType.defaultIntervalDays;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary, onPrimary: Colors.white, surface: _kCardBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final result = await widget.service.setContraceptionReminder(
      userId: widget.userId,
      type: _selectedType,
      startDate: _startDate,
      intervalDays: _intervalDays,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isSwahili ? 'Kikumbusho kimehifadhiwa' : 'Reminder saved'), backgroundColor: _kPrimary),
      );
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (widget.isSwahili ? 'Imeshindwa kuhifadhi' : 'Failed to save')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _kSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(widget.isSwahili ? 'Ongeza Kikumbusho' : 'Add Reminder', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 16),

            // Type selector
            Text(widget.isSwahili ? 'Njia' : 'Method', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ContraceptionType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      _intervalDays = type.defaultIntervalDays;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _kPrimary : const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, size: 16, color: isSelected ? Colors.white : _kPrimary),
                        const SizedBox(width: 6),
                        Text(type.displayName(widget.isSwahili), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : _kPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Start date
            Text(widget.isSwahili ? 'Tarehe ya kuanza' : 'Start date', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickStartDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: _kPrimary),
                    const SizedBox(width: 10),
                    Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontSize: 14, color: _kPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interval
            if (_selectedType.defaultIntervalDays > 0) ...[
              Text(widget.isSwahili ? 'Muda (siku)' : 'Interval (days)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded, size: 18, color: _kPrimary),
                    const SizedBox(width: 10),
                    Text(
                      _intervalDays == 1
                          ? (widget.isSwahili ? 'Kila siku' : 'Every day')
                          : (widget.isSwahili ? 'Kila siku $_intervalDays' : 'Every $_intervalDays days'),
                      style: const TextStyle(fontSize: 14, color: _kPrimary),
                    ),
                    const Spacer(),
                    Text(
                      _selectedType == ContraceptionType.injectable ? 'Depo-Provera' : '',
                      style: const TextStyle(fontSize: 10, color: _kSecondary, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isSwahili ? 'Hifadhi Kikumbusho' : 'Save Reminder', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
