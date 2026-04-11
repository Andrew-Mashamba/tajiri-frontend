// lib/notes/pages/add_note_page.dart
import 'package:flutter/material.dart';
import '../models/notes_models.dart';
import '../services/notes_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddNotePage extends StatefulWidget {
  final int userId;
  const AddNotePage({super.key, required this.userId});
  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final NotesService _service = NotesService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _hasChecklist = false;
  NoteColor _color = NoteColor.defaultColor;
  List<ChecklistItem> _checklistItems = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _addChecklistItem() {
    setState(() {
      _checklistItems = [
        ..._checklistItems,
        ChecklistItem(title: ''),
      ];
    });
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems = List.from(_checklistItems)..removeAt(index);
    });
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      _checklistItems = List.from(_checklistItems);
      _checklistItems[index] =
          _checklistItems[index].copyWith(isDone: !_checklistItems[index].isDone);
    });
  }

  void _updateChecklistItemTitle(int index, String title) {
    _checklistItems = List.from(_checklistItems);
    _checklistItems[index] = _checklistItems[index].copyWith(title: title);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka kichwa')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Filter out empty checklist items
    final items = _checklistItems
        .where((i) => i.title.trim().isNotEmpty)
        .toList();

    final note = Note(
      id: 0,
      userId: widget.userId,
      title: title,
      body: _hasChecklist ? null : _bodyController.text.trim(),
      hasChecklist: _hasChecklist,
      checklistItems: _hasChecklist ? items : [],
      color: _color,
    );

    final result = await _service.createNote(note);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kumbukumbu imeundwa')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _color.tint == const Color(0xFFFFFFFF)
          ? _kBackground
          : _color.tint,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kumbukumbu Mpya',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _isSaving ? null : _save,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Hifadhi',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          TextField(
            controller: _titleController,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
            decoration: const InputDecoration(
              hintText: 'Kichwa',
              hintStyle: TextStyle(color: _kSecondary),
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Checklist toggle & color
          Row(
            children: [
              _buildModeChip(
                icon: Icons.notes_rounded,
                label: 'Maandishi',
                isActive: !_hasChecklist,
                onTap: () => setState(() => _hasChecklist = false),
              ),
              const SizedBox(width: 8),
              _buildModeChip(
                icon: Icons.checklist_rounded,
                label: 'Orodha',
                isActive: _hasChecklist,
                onTap: () => setState(() {
                  _hasChecklist = true;
                  if (_checklistItems.isEmpty) _addChecklistItem();
                }),
              ),
              const Spacer(),
              // Color picker
              PopupMenuButton<NoteColor>(
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _color.tint,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.2)),
                  ),
                ),
                itemBuilder: (_) => NoteColor.values
                    .map((c) => PopupMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: c.tint,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          _kPrimary.withValues(alpha: 0.15)),
                                ),
                                child: _color == c
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: _kPrimary)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(c.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onSelected: (c) => setState(() => _color = c),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Body or checklist
          if (_hasChecklist) ...[
            ..._checklistItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleChecklistItem(i),
                      child: Icon(
                        item.isDone
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 22,
                        color: item.isDone ? _kSecondary : _kPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: item.title),
                        onChanged: (v) => _updateChecklistItemTitle(i, v),
                        style: TextStyle(
                          fontSize: 14,
                          color: item.isDone ? _kSecondary : _kPrimary,
                          decoration: item.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Kitu kipya...',
                          hintStyle: TextStyle(color: _kSecondary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeChecklistItem(i),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: _kSecondary),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addChecklistItem,
              icon: const Icon(Icons.add_rounded, size: 18, color: _kPrimary),
              label: const Text('Ongeza kipengele',
                  style: TextStyle(fontSize: 13, color: _kPrimary)),
            ),
          ] else
            Container(
              constraints: const BoxConstraints(minHeight: 200),
              child: TextField(
                controller: _bodyController,
                maxLines: null,
                style: const TextStyle(fontSize: 15, color: _kPrimary),
                decoration: const InputDecoration(
                  hintText: 'Anza kuandika...',
                  hintStyle: TextStyle(color: _kSecondary),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: _kPrimary.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : _kSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _kSecondary)),
          ],
        ),
      ),
    );
  }
}
