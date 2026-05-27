// lib/models/task.dart
import 'dart:convert';

/// Immutable data class representing a single reminder task.
class Task {
  final String id;
  final String text;
  final DateTime? deadline;
  final bool completed;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.text,
    this.deadline,
    required this.completed,
    required this.createdAt,
  });

  /// Returns true when the deadline has passed and the task is not yet done.
  bool get isOverdue {
    if (deadline == null || completed) return false;
    return deadline!.isBefore(DateTime.now());
  }

  /// Creates a copy with selectively overridden fields.
  /// Set [clearDeadline] to true to explicitly null the deadline.
  Task copyWith({
    String? id,
    String? text,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? completed,
    DateTime? createdAt,
  }) =>
      Task(
        id: id ?? this.id,
        text: text ?? this.text,
        deadline: clearDeadline ? null : (deadline ?? this.deadline),
        completed: completed ?? this.completed,
        createdAt: createdAt ?? this.createdAt,
      );

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'deadline': deadline?.toIso8601String(),
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        text: json['text'] as String,
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        completed: json['completed'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<Task> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<Task> tasks) =>
      jsonEncode(tasks.map((t) => t.toJson()).toList());
}
