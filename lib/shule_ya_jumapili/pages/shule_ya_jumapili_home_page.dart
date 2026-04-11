// lib/shule_ya_jumapili/pages/shule_ya_jumapili_home_page.dart
import 'package:flutter/material.dart';
import '../models/shule_ya_jumapili_models.dart';
import '../services/shule_ya_jumapili_service.dart';
import '../widgets/lesson_card.dart';
import 'lesson_detail_page.dart';
import 'attendance_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class ShuleYaJumapiliHomePage extends StatefulWidget {
  final int userId;
  const ShuleYaJumapiliHomePage({super.key, required this.userId});
  @override
  State<ShuleYaJumapiliHomePage> createState() => _ShuleYaJumapiliHomePageState();
}

class _ShuleYaJumapiliHomePageState extends State<ShuleYaJumapiliHomePage> {
  List<SundaySchoolLesson> _lessons = [];
  List<ChildProfile> _children = [];
  bool _isLoading = true;
  String? _ageFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ShuleYaJumapiliService.getLessons(ageGroup: _ageFilter),
      ShuleYaJumapiliService.getChildren(),
    ]);
    if (mounted) {
      final lesR = results[0] as PaginatedResult<SundaySchoolLesson>;
      final chiR = results[1] as PaginatedResult<ChildProfile>;
      setState(() {
        _isLoading = false;
        if (lesR.success) _lessons = lesR.items;
        if (chiR.success) _children = chiR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _load,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Attendance button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.checklist_rounded, size: 22, color: _kPrimary),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AttendancePage())),
                  ),
                ),
                  // Children summary
                  if (_children.isNotEmpty) ...[
                    const Text('Watoto Wangu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text('My Children',
                        style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _children.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final c = _children[i];
                          return Container(
                            width: 140,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: _kSecondary),
                                    const SizedBox(width: 4),
                                    Text('${c.attendanceCount} siku / days',
                                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.menu_book_rounded, size: 14, color: _kSecondary),
                                    const SizedBox(width: 4),
                                    Text('${c.memoryVerseCount} aya / verses',
                                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Age filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Masomo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                          Text('Lessons',
                              style: TextStyle(fontSize: 12, color: _kSecondary)),
                        ],
                      ),
                      PopupMenuButton<String?>(
                        icon: const Icon(Icons.filter_list_rounded, color: _kPrimary),
                        onSelected: (v) { _ageFilter = v; _load(); },
                        itemBuilder: (_) => [
                          const PopupMenuItem<String?>(value: null, child: Text('Zote / All')),
                          ...AgeGroup.values.map((a) =>
                              PopupMenuItem(value: a.name, child: Text(a.label))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_lessons.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text('Hakuna masomo / No lessons',
                          style: TextStyle(color: _kSecondary, fontSize: 13)),
                    )
                  else
                    ..._lessons.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LessonCard(
                            lesson: l,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => LessonDetailPage(lesson: l))),
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }
}
