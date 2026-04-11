// lib/class_notes/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import '../models/class_notes_models.dart';
import '../services/class_notes_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class NoteDetailPage extends StatelessWidget {
  final ClassNote note;
  final int userId;
  const NoteDetailPage({super.key, required this.note, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        title: const Text('Maelezo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(note.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded), onPressed: () async {
            final result = await ClassNotesService().bookmarkNote(note.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result.success ? 'Imehifadhiwa / Bookmarked' : 'Imeshindwa / Failed'),
              ));
            }
          }),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(note.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 6),
          Text('${note.subject}${note.courseCode != null ? ' · ${note.courseCode}' : ''}', style: const TextStyle(fontSize: 14, color: _kSecondary)),
          const SizedBox(height: 4),
          if (note.topic != null) Text('Mada: ${note.topic}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 16),
          // Stats
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat(Icons.star_rounded, '${note.rating.toStringAsFixed(1)}', '${note.ratingCount} ratings'),
              _stat(Icons.download_rounded, '${note.downloadCount}', 'downloads'),
              _stat(Icons.visibility_rounded, '${note.viewCount}', 'views'),
            ]),
          ),
          const SizedBox(height: 16),
          // Uploader
          Row(children: [
            CircleAvatar(radius: 16, backgroundColor: _kPrimary.withValues(alpha: 0.1),
              backgroundImage: note.uploaderAvatar != null ? NetworkImage(note.uploaderAvatar!) : null,
              child: note.uploaderAvatar == null ? Text(note.uploaderName.isNotEmpty ? note.uploaderName[0] : '?', style: const TextStyle(fontSize: 12, color: _kPrimary)) : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(note.uploaderName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${note.fileSizeFormatted} · ${note.format.displayName}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ])),
          ]),
          const SizedBox(height: 16),
          if (note.description != null) ...[
            const Text('Maelezo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 6),
            Text(note.description!, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5)),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inapakua... / Downloading...'))),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Pakua / Download'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          ),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, size: 18, color: _kPrimary),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
    ]);
  }
}
