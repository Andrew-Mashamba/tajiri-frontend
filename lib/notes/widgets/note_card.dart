// lib/notes/widgets/note_card.dart
import 'package:flutter/material.dart';
import '../models/notes_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.isGrid = false,
  });

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inMinutes < 60) return 'Dak ${diff.inMinutes} zilizopita';
    if (diff.inHours < 24) return 'Saa ${diff.inHours} zilizopita';
    if (diff.inDays < 7) return 'Siku ${diff.inDays} zilizopita';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: note.color.tint,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _kPrimary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              Row(
                children: [
                  if (note.isPinned) ...[
                    const Icon(Icons.push_pin_rounded,
                        size: 14, color: _kPrimary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: isGrid ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Body or checklist preview
              if (note.hasChecklist && note.checklistItems.isNotEmpty) ...[
                ...note.checklistItems.take(isGrid ? 4 : 3).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Icon(
                              item.isDone
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 16,
                              color: item.isDone
                                  ? _kSecondary
                                  : _kPrimary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: item.isDone
                                      ? _kSecondary
                                      : _kPrimary,
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (note.checklistItems.length > (isGrid ? 4 : 3))
                  Text(
                    '+${note.checklistItems.length - (isGrid ? 4 : 3)} zaidi',
                    style: const TextStyle(
                        fontSize: 11, color: _kSecondary),
                  ),
              ] else if (note.body != null && note.body!.isNotEmpty)
                Text(
                  note.body!,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: isGrid ? 6 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              // Date
              Text(
                _fmtDate(note.updatedAt ?? note.createdAt),
                style:
                    TextStyle(fontSize: 11, color: _kSecondary.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
