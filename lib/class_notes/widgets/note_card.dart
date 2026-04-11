// lib/class_notes/widgets/note_card.dart
import 'package:flutter/material.dart';
import '../models/class_notes_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NoteCard extends StatelessWidget {
  final ClassNote note;
  final VoidCallback? onTap;
  const NoteCard({super.key, required this.note, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            child: Icon(_formatIcon(note.format), color: _kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(note.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${note.subject} · ${note.fileSizeFormatted}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
              const SizedBox(width: 2),
              Text(note.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: _kSecondary)),
              const SizedBox(width: 10),
              const Icon(Icons.download_rounded, size: 13, color: _kSecondary),
              const SizedBox(width: 2),
              Text('${note.downloadCount}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
        ]),
      ),
    );
  }

  IconData _formatIcon(NoteFormat f) {
    switch (f) {
      case NoteFormat.pdf: return Icons.picture_as_pdf_rounded;
      case NoteFormat.image: return Icons.image_rounded;
      case NoteFormat.document: return Icons.description_rounded;
      case NoteFormat.slides: return Icons.slideshow_rounded;
    }
  }
}
