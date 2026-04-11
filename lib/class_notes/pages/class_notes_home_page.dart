// lib/class_notes/pages/class_notes_home_page.dart
import 'package:flutter/material.dart';
import '../models/class_notes_models.dart';
import '../services/class_notes_service.dart';
import 'upload_note_page.dart';
import 'note_detail_page.dart';
import '../widgets/note_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ClassNotesHomePage extends StatefulWidget {
  final int userId;
  const ClassNotesHomePage({super.key, required this.userId});
  @override
  State<ClassNotesHomePage> createState() => _ClassNotesHomePageState();
}

class _ClassNotesHomePageState extends State<ClassNotesHomePage> {
  final ClassNotesService _service = ClassNotesService();
  List<ClassNote> _notes = [];
  bool _isLoading = true;
  final _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadNotes({String? search}) async {
    setState(() => _isLoading = true);
    final result = await _service.getNotes(search: search);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _notes = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotes,
          color: _kPrimary,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.note_alt_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text('Maelezo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text('Class Notes — ${_notes.length} maelezo', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            // Search
            TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: 'Tafuta maelezo...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onSubmitted: (v) => _loadNotes(search: v.trim()),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_notes.isEmpty)
              Container(padding: const EdgeInsets.all(48), alignment: Alignment.center, child: const Column(children: [
                Icon(Icons.note_outlined, size: 48, color: _kSecondary),
                SizedBox(height: 8),
                Text('Hakuna maelezo bado', style: TextStyle(color: _kSecondary, fontSize: 14)),
                Text('No notes yet — upload some!', style: TextStyle(color: _kSecondary, fontSize: 12)),
              ]))
            else
              ..._notes.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NoteCard(note: n, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailPage(note: n, userId: widget.userId)))),
              )),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadNotePage(userId: widget.userId))).then((_) => _loadNotes()),
        child: const Icon(Icons.upload_rounded, color: Colors.white),
      ),
    );
  }
}
