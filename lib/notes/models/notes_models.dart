// lib/notes/models/notes_models.dart

// ─── Note Color ───────────────────────────────────────────────

import 'package:flutter/material.dart';

enum NoteColor {
  defaultColor,
  yellow,
  green,
  blue,
  pink,
  purple;

  Color get tint {
    switch (this) {
      case NoteColor.defaultColor:
        return const Color(0xFFFFFFFF);
      case NoteColor.yellow:
        return const Color(0xFFFFF9C4);
      case NoteColor.green:
        return const Color(0xFFC8E6C9);
      case NoteColor.blue:
        return const Color(0xFFBBDEFB);
      case NoteColor.pink:
        return const Color(0xFFF8BBD0);
      case NoteColor.purple:
        return const Color(0xFFE1BEE7);
    }
  }

  String get displayName {
    switch (this) {
      case NoteColor.defaultColor:
        return 'Nyeupe';
      case NoteColor.yellow:
        return 'Njano';
      case NoteColor.green:
        return 'Kijani';
      case NoteColor.blue:
        return 'Bluu';
      case NoteColor.pink:
        return 'Pinki';
      case NoteColor.purple:
        return 'Zambarau';
    }
  }

  static NoteColor fromString(String? s) {
    if (s == 'default') return NoteColor.defaultColor;
    return NoteColor.values.firstWhere(
      (v) => v.name == s,
      orElse: () => NoteColor.defaultColor,
    );
  }

  String toApiString() {
    if (this == NoteColor.defaultColor) return 'default';
    return name;
  }
}

// ─── Checklist Item ───────────────────────────────────────────

class ChecklistItem {
  final String title;
  final bool isDone;

  ChecklistItem({required this.title, this.isDone = false});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      title: json['title'] ?? '',
      isDone: _parseBool(json['is_done']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'is_done': isDone,
      };

  ChecklistItem copyWith({String? title, bool? isDone}) {
    return ChecklistItem(
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

// ─── Note ─────────────────────────────────────────────────────

class Note {
  final int id;
  final int userId;
  final String title;
  final String? body;
  final bool isPinned;
  final NoteColor color;
  final bool hasChecklist;
  final List<ChecklistItem> checklistItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.isPinned = false,
    this.color = NoteColor.defaultColor,
    this.hasChecklist = false,
    this.checklistItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    List<ChecklistItem> items = [];
    if (json['checklist_items'] != null) {
      if (json['checklist_items'] is List) {
        items = (json['checklist_items'] as List)
            .map((j) => ChecklistItem.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    }

    return Note(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      title: json['title'] ?? '',
      body: json['body'],
      isPinned: _parseBool(json['is_pinned']),
      color: NoteColor.fromString(json['color']),
      hasChecklist: _parseBool(json['has_checklist']),
      checklistItems: items,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'body': body,
        'is_pinned': isPinned,
        'color': color.toApiString(),
        'has_checklist': hasChecklist,
        'checklist_items':
            checklistItems.map((i) => i.toJson()).toList(),
      };

  String get preview {
    if (hasChecklist && checklistItems.isNotEmpty) {
      final done = checklistItems.where((i) => i.isDone).length;
      return '$done/${checklistItems.length} vitu vimekamilika';
    }
    return body ?? '';
  }

  String get shareText {
    final buf = StringBuffer(title);
    if (hasChecklist && checklistItems.isNotEmpty) {
      buf.writeln();
      for (final item in checklistItems) {
        buf.writeln('${item.isDone ? "[x]" : "[ ]"} ${item.title}');
      }
    } else if (body != null && body!.isNotEmpty) {
      buf.writeln();
      buf.write(body);
    }
    return buf.toString();
  }
}

// ─── Result wrappers ──────────────────────────────────────────

class NotesResult<T> {
  final bool success;
  final T? data;
  final String? message;
  NotesResult({required this.success, this.data, this.message});
}

class NotesListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  NotesListResult(
      {required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v == 'true';
  return false;
}
