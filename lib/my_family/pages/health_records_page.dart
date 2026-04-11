// lib/my_family/pages/health_records_page.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';
import '../widgets/health_record_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class HealthRecordsPage extends StatefulWidget {
  final int userId;
  final List<FamilyMember> members;

  const HealthRecordsPage({
    super.key,
    required this.userId,
    required this.members,
  });

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage> {
  final MyFamilyService _service = MyFamilyService();

  List<FamilyHealthRecord> _records = [];
  bool _isLoading = true;
  int? _filterMemberId;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final result = await _service.getHealthRecords(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _records = result.items;
      });
    }
  }

  List<FamilyHealthRecord> get _filteredRecords {
    if (_filterMemberId == null) return _records;
    return _records
        .where((r) => r.memberId == _filterMemberId)
        .toList();
  }

  Map<HealthRecordType, List<FamilyHealthRecord>> get _groupedByType {
    final grouped = <HealthRecordType, List<FamilyHealthRecord>>{};
    for (final r in _filteredRecords) {
      grouped.putIfAbsent(r.type, () => []);
      grouped[r.type]!.add(r);
    }
    return grouped;
  }

  Future<void> _deleteRecord(FamilyHealthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Rekodi'),
        content: Text('Una uhakika unataka kufuta "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana',
                style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ndio, Futa',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _service.deleteHealthRecord(record.id);
      if (result.success && mounted) _loadRecords();
    }
  }

  void _showAddRecordSheet() {
    final titleCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    HealthRecordType selectedType = HealthRecordType.vaccination;
    int? selectedMemberId =
        widget.members.isNotEmpty ? widget.members.first.id : null;
    String? selectedMemberName =
        widget.members.isNotEmpty ? widget.members.first.name : null;
    DateTime recordDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ongeza Rekodi ya Afya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Record type
                    const Text(
                      'Aina ya Rekodi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: HealthRecordType.values.map((type) {
                        return ChoiceChip(
                          avatar: Icon(type.icon,
                              size: 14,
                              color: selectedType == type
                                  ? Colors.white
                                  : type.color),
                          label: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedType == type
                                  ? Colors.white
                                  : _kPrimary,
                            ),
                          ),
                          selected: selectedType == type,
                          onSelected: (_) =>
                              setSheetState(() => selectedType = type),
                          selectedColor: _kPrimary,
                          backgroundColor:
                              _kPrimary.withValues(alpha: 0.06),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Member selector
                    if (widget.members.isNotEmpty) ...[
                      const Text(
                        'Mwanafamilia',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: selectedMemberId,
                        items: widget.members.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() {
                              selectedMemberId = v;
                              selectedMemberName = widget.members
                                  .firstWhere((m) => m.id == v)
                                  .name;
                            });
                          }
                        },
                        style: const TextStyle(
                            fontSize: 14, color: _kPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _kBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Title
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(
                          fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Kichwa (mfano: Chanjo ya Tetanasi)',
                        labelStyle: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Details
                    TextField(
                      controller: detailsCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                          fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Maelezo zaidi',
                        labelStyle: const TextStyle(
                            fontSize: 13, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: recordDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _kPrimary,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => recordDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: _kSecondary),
                            const SizedBox(width: 10),
                            Text(
                              '${recordDate.day}/${recordDate.month}/${recordDate.year}',
                              style: const TextStyle(
                                  fontSize: 14, color: _kPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty ||
                              selectedMemberId == null) {
                            return;
                          }
                          final result = await _service.addHealthRecord(
                            userId: widget.userId,
                            memberId: selectedMemberId!,
                            memberName: selectedMemberName ?? '',
                            type: selectedType.name,
                            title: titleCtrl.text.trim(),
                            details: detailsCtrl.text.trim().isNotEmpty
                                ? detailsCtrl.text.trim()
                                : null,
                            date: recordDate
                                .toIso8601String()
                                .split('T')
                                .first,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (result.success && mounted) _loadRecords();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hifadhi Rekodi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Afya ya Familia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadRecords,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Member Filter ────────────────────────
                  if (widget.members.isNotEmpty) ...[
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'Wote',
                            isSelected: _filterMemberId == null,
                            onTap: () => setState(
                                () => _filterMemberId = null),
                          ),
                          ...widget.members.map((m) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 6),
                                child: _FilterChip(
                                  label: m.name.split(' ').first,
                                  isSelected:
                                      _filterMemberId == m.id,
                                  onTap: () => setState(
                                      () => _filterMemberId = m.id),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Health Summary Cards ─────────────────
                  if (_filteredRecords.isNotEmpty) ...[
                    Row(
                      children: HealthRecordType.values.map((type) {
                        final count = _filteredRecords
                            .where((r) => r.type == type)
                            .length;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(type.icon,
                                    size: 20, color: type.color),
                                const SizedBox(height: 4),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary,
                                  ),
                                ),
                                Text(
                                  type.displayName,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: _kSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Records grouped by type ──────────────
                  if (_filteredRecords.isEmpty)
                    _buildEmptyState()
                  else
                    ..._groupedByType.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(entry.key.icon,
                                  size: 16, color: entry.key.color),
                              const SizedBox(width: 6),
                              Text(
                                entry.key.displayName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map((r) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: HealthRecordCard(
                                  record: r,
                                  onDelete: () => _deleteRecord(r),
                                ),
                              )),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.health_and_safety_rounded,
                size: 64, color: _kPrimary.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            const Text(
              'Bado hakuna rekodi za afya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ongeza rekodi za chanjo, mizio, magonjwa, na dawa za familia yako',
              style: TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _showAddRecordSheet,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ongeza Rekodi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _kPrimary,
          ),
        ),
      ),
    );
  }
}
