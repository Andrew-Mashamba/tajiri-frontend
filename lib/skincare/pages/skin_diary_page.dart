// lib/skincare/pages/skin_diary_page.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SkinDiaryPage extends StatefulWidget {
  final int userId;
  const SkinDiaryPage({super.key, required this.userId});
  @override
  State<SkinDiaryPage> createState() => _SkinDiaryPageState();
}

class _SkinDiaryPageState extends State<SkinDiaryPage> {
  final SkincareService _service = SkincareService();

  List<SkinDiaryEntry> _entries = [];
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();

  // New entry form
  int _mood = 3;
  final Set<String> _selectedTags = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _productsController = TextEditingController();
  bool _isSaving = false;

  final List<String> _availableTags = [
    'Chunusi', 'Ukavu', 'Mafuta', 'Ngozi safi', 'Madoa',
    'Kuwashwa', 'Jua', 'Jasho', 'Maji mengi', 'Mazoezi',
    'Hedhi', 'Msongo', 'Usingizi mzuri', 'Usingizi mbaya',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final result = await _service.getDiaryEntries(
      widget.userId,
      month: _currentMonth.month,
      year: _currentMonth.year,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _entries = result.items;
      });
    }
  }

  Set<int> get _loggedDays => _entries.map((e) => e.date.day).toSet();

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _loadEntries();
  }

  Future<void> _logEntry() async {
    setState(() => _isSaving = true);
    final products = _productsController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final result = await _service.logDiaryEntry(
      userId: widget.userId,
      date: DateTime.now(),
      mood: _mood,
      tags: _selectedTags.toList(),
      productsUsed: products,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        _notesController.clear();
        _productsController.clear();
        _selectedTags.clear();
        _mood = 3;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary imehifadhiwa'), backgroundColor: _kPrimary),
        );
        _loadEntries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Diary ya Ngozi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Calendar section
                _buildCalendar(),
                const SizedBox(height: 20),

                // New entry form
                const Text('Andika Leo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 12),
                _buildMoodSelector(),
                const SizedBox(height: 12),
                _buildTagSelector(),
                const SizedBox(height: 12),
                _buildProductsInput(),
                const SizedBox(height: 12),
                _buildNotesInput(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _logEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Hifadhi', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),

                // History
                if (_entries.isNotEmpty) ...[
                  const Text('Historia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 10),
                  ..._entries.map((entry) => _buildEntryCard(entry)),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final monthNames = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: _kPrimary),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: _kPrimary),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday labels
          Row(
            children: ['Jt', 'Jn', 'Jt', 'Al', 'Ij', 'Jm', 'Jp']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kSecondary)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: ((firstWeekday - 1) % 7) + daysInMonth,
            itemBuilder: (context, index) {
              final offset = (firstWeekday - 1) % 7;
              if (index < offset) return const SizedBox();
              final day = index - offset + 1;
              final isLogged = _loggedDays.contains(day);
              final isToday = DateTime.now().year == _currentMonth.year &&
                  DateTime.now().month == _currentMonth.month &&
                  DateTime.now().day == day;

              return Container(
                decoration: BoxDecoration(
                  color: isLogged
                      ? _kPrimary
                      : isToday
                          ? _kPrimary.withValues(alpha: 0.08)
                          : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday || isLogged ? FontWeight.w700 : FontWeight.w400,
                      color: isLogged ? Colors.white : _kPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = [
      (1, Icons.sentiment_very_dissatisfied_rounded, 'Mbaya sana'),
      (2, Icons.sentiment_dissatisfied_rounded, 'Mbaya'),
      (3, Icons.sentiment_neutral_rounded, 'Kawaida'),
      (4, Icons.sentiment_satisfied_rounded, 'Nzuri'),
      (5, Icons.sentiment_very_satisfied_rounded, 'Nzuri sana'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hali ya Ngozi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((m) {
              final isSelected = _mood == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _mood = m.$1),
                child: Column(
                  children: [
                    Icon(
                      m.$2,
                      size: isSelected ? 34 : 28,
                      color: isSelected ? _kPrimary : _kSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.$3,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? _kPrimary : _kSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lebo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag, style: TextStyle(fontSize: 11, color: _kPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                selected: isSelected,
                onSelected: (s) => setState(() => s ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
                selectedColor: _kPrimary.withValues(alpha: 0.12),
                backgroundColor: _kCardBg,
                checkmarkColor: _kPrimary,
                side: BorderSide(color: isSelected ? _kPrimary : _kPrimary.withValues(alpha: 0.1)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bidhaa Ulizotumia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _productsController,
            decoration: InputDecoration(
              hintText: 'k.m. CeraVe, Nivea sunscreen (tenganisha kwa koma)',
              hintStyle: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Maelezo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Andika kuhusu hali ya ngozi yako leo...',
              hintStyle: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(SkinDiaryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(entry.moodIcon, size: 24, color: _kPrimary),
                const SizedBox(width: 10),
                Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.moodEmoji,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                ),
              ],
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notes!,
                style: const TextStyle(fontSize: 13, color: _kPrimary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4, runSpacing: 4,
                children: entry.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 10, color: _kSecondary)),
                    )).toList(),
              ),
            ],
            if (entry.productsUsed.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Bidhaa: ${entry.productsUsed.join(", ")}',
                style: TextStyle(fontSize: 11, color: _kSecondary.withValues(alpha: 0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
