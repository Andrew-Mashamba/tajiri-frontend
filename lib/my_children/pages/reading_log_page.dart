// lib/my_children/pages/reading_log_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ReadingLogPage extends StatefulWidget {
  final Child child;
  final int userId;

  const ReadingLogPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<ReadingLogPage> createState() => _ReadingLogPageState();
}

class _ReadingLogPageState extends State<ReadingLogPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<ReadingLogEntry> _entries = [];
  String? _token;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result =
          await _service.getReadingHistory(_token!, widget.child.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _entries = result.items;
      });
      // Schedule daily reading reminder with current streak
      if (result.success && result.items.isNotEmpty) {
        final streak = _calculateStreak();
        ChildrenNotificationHelper.scheduleReadingReminder(
          widget.child.id, widget.child.name, streak, _sw,
        ).catchError((_) {});
      }
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

    final totalBooks = _entries.length;
    final completedBooks = _entries.where((e) => e.isCompleted).length;
    final totalPages =
        _entries.fold<int>(0, (sum, e) => sum + e.pagesRead);

    // Reading streak: count consecutive days with entries (simplified)
    final streak = _calculateStreak();

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Daftari la Kusoma' : 'Reading Log',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadEntries,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                sw ? 'Vitabu' : 'Books', '$totalBooks')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatCard(
                                sw ? 'Vilivyomalizika' : 'Completed',
                                '$completedBooks')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatCard(
                                sw ? 'Kurasa' : 'Pages', '$totalPages')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Streak card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            sw
                                ? 'Mfuatano wa kusoma: siku $streak'
                                : 'Reading streak: $streak days',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Books list
                    if (_entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            sw
                                ? 'Hakuna vitabu bado. Ongeza kitabu.'
                                : 'No books yet. Log a book.',
                            style: const TextStyle(
                                fontSize: 15, color: _kSecondary),
                          ),
                        ),
                      )
                    else
                      ..._entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildBookCard(sw, e),
                          )),

                    // ─── Cross-module links ──────────────────
                    const SizedBox(height: 16),
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
                      icon: Icons.shopping_cart_rounded,
                      label: sw
                          ? 'Nunua vitabu vya watoto'
                          : 'Shop children\'s books',
                      onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.chat_rounded,
                      label: sw
                          ? 'Uliza Shangazi mapendekezo ya vitabu kwa miaka ${widget.child.ageInYears}'
                          : 'Ask Shangazi for book recommendations for age ${widget.child.ageInYears}',
                      onTap: () => Navigator.pushNamed(context, '/chat/0'),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(bool sw, ReadingLogEntry entry) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteReading(entry.id, entry.bookTitle),
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
              const Icon(Icons.menu_book_rounded,
                  size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.bookTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.isCompleted)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Colors.green),
            ],
          ),
          if (entry.author != null && entry.author!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.author!,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (entry.totalPages != null && entry.totalPages! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: entry.progress,
                      backgroundColor: Colors.grey.shade200,
                      color: _kPrimary,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.pagesRead}/${entry.totalPages}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '${sw ? "Kurasa" : "Pages"}: ${entry.pagesRead}',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _confirmDeleteReading(int id, String label) {
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
                    await _service.deleteReading(_token!, id);
                if (!mounted) return;
                if (result.success) {
                  _loadEntries();
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        sw ? 'Kitabu kimefutwa' : 'Book deleted'),
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

  int _calculateStreak() {
    if (_entries.isEmpty) return 0;

    // Collect unique days that have entries
    final dates = <String>{};
    for (final e in _entries) {
      final d = e.startDate ?? e.finishDate;
      if (d != null) {
        dates.add('${d.year}-${d.month}-${d.day}');
      }
    }
    if (dates.isEmpty) return 0;

    // Count backwards from today
    int streak = 0;
    DateTime check = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final key = '${check.year}-${check.month}-${check.day}';
      if (dates.contains(key)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  void _showAddDialog() {
    final sw = _sw;
    final titleCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();
    final totalPagesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Andika Kitabu' : 'Log Book',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: sw ? 'Jina la Kitabu' : 'Book Title',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pagesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: sw ? 'Kurasa zilizosomwa' : 'Pages Read',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: totalPagesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            sw ? 'Jumla ya kurasa' : 'Total Pages',
                        hintText: sw ? 'Si lazima' : 'Optional',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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
                    final title = titleCtrl.text.trim();
                    final pages =
                        int.tryParse(pagesCtrl.text.trim()) ?? 0;
                    if (title.isEmpty || pages <= 0) return;
                    _submitReading(
                      ctx,
                      title,
                      pages,
                      int.tryParse(totalPagesCtrl.text.trim()),
                    );
                  },
                  child: Text(sw ? 'Hifadhi' : 'Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReading(
      BuildContext ctx, String title, int pages, int? totalPages) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(ctx).pop();

    try {
      final result = await _service.logReading(
        token: _token!,
        childId: widget.child.id,
        bookTitle: title,
        pagesRead: pages,
        totalPages: totalPages,
        startDate: DateTime.now(),
      );
      if (!mounted) return;
      if (result.success) {
        _loadEntries();
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Kitabu kimeandikwa' : 'Book logged'),
          ),
        );
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
