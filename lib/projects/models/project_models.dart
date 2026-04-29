// lib/projects/models/project_models.dart
int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

enum ProjectStatus { active, completed, onHold }

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high }

ProjectStatus _parseProjectStatus(dynamic v) {
  switch (v?.toString()) {
    case 'completed':
      return ProjectStatus.completed;
    case 'on_hold':
      return ProjectStatus.onHold;
    default:
      return ProjectStatus.active;
  }
}

TaskStatus _parseTaskStatus(dynamic v) {
  switch (v?.toString()) {
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'done':
      return TaskStatus.done;
    default:
      return TaskStatus.todo;
  }
}

TaskPriority _parseTaskPriority(dynamic v) {
  switch (v?.toString()) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    default:
      return TaskPriority.medium;
  }
}

class Project {
  final int? id;
  final int? businessId;
  final String title;
  final String description;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int taskCount;
  final int completedCount;

  const Project({
    this.id,
    this.businessId,
    required this.title,
    this.description = '',
    this.status = ProjectStatus.active,
    this.startDate,
    this.endDate,
    this.taskCount = 0,
    this.completedCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: _parseInt(json['id']),
        businessId: _parseInt(json['business_id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: _parseProjectStatus(json['status']),
        startDate: _parseDate(json['start_date']),
        endDate: _parseDate(json['end_date']),
        taskCount: _parseInt(json['task_count']) ?? 0,
        completedCount: _parseInt(json['completed_count']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'title': title,
        'description': description,
        'status': switch (status) {
          ProjectStatus.active => 'active',
          ProjectStatus.completed => 'completed',
          ProjectStatus.onHold => 'on_hold',
        },
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
}

class Task {
  final int? id;
  final int? projectId;
  final String title;
  final String description;
  final int? assigneeId;
  final String? assigneeName;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;

  const Task({
    this.id,
    this.projectId,
    required this.title,
    this.description = '',
    this.assigneeId,
    this.assigneeName,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: _parseInt(json['id']),
        projectId: _parseInt(json['project_id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        assigneeId: _parseInt(json['assignee_id']),
        assigneeName: json['assignee_name']?.toString(),
        dueDate: _parseDate(json['due_date']),
        priority: _parseTaskPriority(json['priority']),
        status: _parseTaskStatus(json['status']),
      );

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'due_date': dueDate?.toIso8601String(),
        'priority': switch (priority) {
          TaskPriority.low => 'low',
          TaskPriority.medium => 'medium',
          TaskPriority.high => 'high',
        },
        'status': switch (status) {
          TaskStatus.todo => 'todo',
          TaskStatus.inProgress => 'in_progress',
          TaskStatus.done => 'done',
        },
      };
}
