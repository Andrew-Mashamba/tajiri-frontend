import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../services/saved_search_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 939 — manage saved searches with digest opt-in toggles.
class SavedSearchesPage extends StatefulWidget {
  const SavedSearchesPage({super.key});

  @override
  State<SavedSearchesPage> createState() => _SavedSearchesPageState();
}

class _SavedSearchesPageState extends State<SavedSearchesPage> {
  bool _loading = true;
  List<SavedSearchEntry> _items = const [];
  int? _userId;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = await LocalStorageService.getInstance();
    final uid = storage.getUser()?.userId;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _userId = uid;
    final list = await SavedSearchService.list(userId: uid);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(SavedSearchEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa tafuta?' : 'Delete saved search?'),
        content: Text(e.label),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true || _userId == null) return;
    final success = await SavedSearchService.remove(id: e.id, userId: _userId!);
    if (!mounted) return;
    if (success) _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSwahili ? 'Tafuta Zilizohifadhiwa' : 'Saved Searches'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_border_rounded, size: 56, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _isSwahili ? 'Bado hujahifadhi tafuta' : 'No saved searches yet',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSwahili
                              ? 'Bonyeza ikoni ya bookmark kwenye ukurasa wa tafuta.'
                              : 'Tap the bookmark icon on the search page to save filters.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _bootstrap,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final e = _items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: _kBorder),
                        ),
                        child: ListTile(
                          title: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            _summarizeFilters(e),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB71C1C)),
                            onPressed: () => _delete(e),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _summarizeFilters(SavedSearchEntry e) {
    final parts = <String>[];
    e.filters.forEach((k, v) {
      if (v == null) return;
      parts.add('$k: $v');
    });
    return parts.take(4).join(' • ');
  }
}
