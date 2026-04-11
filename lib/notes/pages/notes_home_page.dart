// lib/notes/pages/notes_home_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/notes_models.dart';
import '../services/notes_service.dart';
import '../widgets/note_card.dart';
import 'note_detail_page.dart';
import 'add_note_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NotesHomePage extends StatefulWidget {
  final int userId;
  const NotesHomePage({super.key, required this.userId});
  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final NotesService _service = NotesService();
  final _searchController = TextEditingController();
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final result = await _service.getNotes(
      widget.userId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _notes = result.items;
      });
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadNotes();
  }

  Future<void> _addNote() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddNotePage(userId: widget.userId),
      ),
    );
    if (result == true && mounted) _loadNotes();
  }

  Future<void> _openNote(Note note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(
          userId: widget.userId,
          noteId: note.id,
        ),
      ),
    );
    if (result == true && mounted) _loadNotes();
  }

  void _showNoteMenu(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                note.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: _kPrimary,
              ),
              title: Text(
                note.isPinned ? 'Ondoa Pin' : 'Bandika Pin',
                style: const TextStyle(color: _kPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(note);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.share_rounded, color: _kPrimary),
              title: const Text('Shiriki',
                  style: TextStyle(color: _kPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _shareNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFE53935)),
              title: const Text('Futa',
                  style: TextStyle(color: Color(0xFFE53935))),
              onTap: () {
                Navigator.pop(ctx);
                _deleteNote(note);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(Note note) async {
    final result = await _service.togglePin(note.id);
    if (mounted) {
      if (result.success) {
        _loadNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa')),
        );
      }
    }
  }

  void _shareNote(Note note) {
    SharePlus.instance.share(ShareParams(text: note.shareText));
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Kumbukumbu?'),
        content: Text('Unahitaji kufuta "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana',
                style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Futa',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _service.deleteNote(note.id);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kumbukumbu imefutwa')),
          );
          _loadNotes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result.message ?? 'Imeshindwa kufuta')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _notes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    final pinned = _notes.where((n) => n.isPinned).toList();
    final unpinned = _notes.where((n) => !n.isPinned).toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadNotes,
          color: _kPrimary,
          child: CustomScrollView(
            slivers: [
              // Search bar + view toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            style: const TextStyle(
                                fontSize: 14, color: _kPrimary),
                            decoration: InputDecoration(
                              hintText: 'Tafuta kumbukumbu...',
                              hintStyle:
                                  TextStyle(color: _kSecondary.withValues(alpha: 0.6)),
                              prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: _kSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _kPrimary.withValues(alpha: 0.08)),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              setState(() => _isGridView = !_isGridView),
                          icon: Icon(
                            _isGridView
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            size: 20,
                            color: _kPrimary,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinned section
              if (pinned.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin_rounded,
                            size: 14, color: _kSecondary),
                        const SizedBox(width: 4),
                        const Text('Zilizobandikwa',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kSecondary)),
                      ],
                    ),
                  ),
                ),
                _buildNoteSection(pinned),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],

              // Unpinned section
              if (unpinned.isNotEmpty) ...[
                if (pinned.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('Nyingine',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kSecondary)),
                    ),
                  ),
                _buildNoteSection(unpinned),
              ],

              // Empty state
              if (_notes.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),

        // FAB — pill button
        Positioned(
          bottom: 16,
          right: 16,
          child: Material(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(28),
            elevation: 4,
            child: InkWell(
              onTap: _addNote,
              borderRadius: BorderRadius.circular(28),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('Kumbukumbu',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(List<Note> notes) {
    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => NoteCard(
              note: notes[i],
              isGrid: true,
              onTap: () => _openNote(notes[i]),
              onLongPress: () => _showNoteMenu(notes[i]),
            ),
            childCount: notes.length,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NoteCard(
              note: notes[i],
              isGrid: false,
              onTap: () => _openNote(notes[i]),
              onLongPress: () => _showNoteMenu(notes[i]),
            ),
          ),
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded,
                size: 56, color: _kSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Hakuna kumbukumbu bado',
                style: TextStyle(fontSize: 16, color: _kSecondary)),
            const SizedBox(height: 6),
            const Text(
                'Anza kuandika mawazo, orodha, na kumbukumbu zako',
                style: TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
