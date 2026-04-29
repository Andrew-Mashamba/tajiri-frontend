// test/projects/project_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/projects/models/project_models.dart';

void main() {
  group('Project.fromJson', () {
    final json = {
      'id': 1,
      'business_id': 2,
      'title': 'Website Redesign',
      'description': 'Redesign the company website',
      'status': 'active',
      'start_date': '2026-01-01',
      'end_date': '2026-06-30',
      'task_count': 10,
      'completed_count': 3,
    };
    test('parses all fields', () {
      final p = Project.fromJson(json);
      expect(p.id, 1);
      expect(p.title, 'Website Redesign');
      expect(p.status, ProjectStatus.active);
      expect(p.taskCount, 10);
      expect(p.completedCount, 3);
      expect(p.startDate?.year, 2026);
    });
    test('unknown status defaults to active', () {
      final p = Project.fromJson({...json, 'status': 'unknown'});
      expect(p.status, ProjectStatus.active);
    });
    test('on_hold status parses correctly', () {
      final p = Project.fromJson({...json, 'status': 'on_hold'});
      expect(p.status, ProjectStatus.onHold);
    });
  });

  group('Task.fromJson', () {
    final json = {
      'id': 5,
      'project_id': 1,
      'title': 'Design mockups',
      'description': 'Create Figma mockups',
      'assignee_id': 3,
      'assignee_name': 'Alice',
      'due_date': '2026-02-15',
      'priority': 'high',
      'status': 'in_progress',
    };
    test('parses all fields', () {
      final t = Task.fromJson(json);
      expect(t.id, 5);
      expect(t.title, 'Design mockups');
      expect(t.priority, TaskPriority.high);
      expect(t.status, TaskStatus.inProgress);
      expect(t.assigneeId, 3);
      expect(t.assigneeName, 'Alice');
    });
    test('unknown priority defaults to medium', () {
      final t = Task.fromJson({...json, 'priority': 'urgent'});
      expect(t.priority, TaskPriority.medium);
    });
    test('unknown status defaults to todo', () {
      final t = Task.fromJson({...json, 'status': 'unknown'});
      expect(t.status, TaskStatus.todo);
    });
    test('toJson round-trips status', () {
      final t = Task.fromJson(json);
      expect(t.toJson()['status'], 'in_progress');
      expect(t.toJson()['priority'], 'high');
    });
  });
}
