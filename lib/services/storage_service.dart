// lib/services/storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

/// Thin wrapper around SharedPreferences.
/// Provides typed read/write for the tasks list (JSON encoded).
class StorageService {
  StorageService._();

  static const String _tasksKey = 'lumina_tasks_v1';

  /// Loads all tasks from persistent storage.
  /// Returns an empty list on first run or on any parse error.
  static Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tasksKey);
      if (raw == null || raw.isEmpty) return [];
      return Task.decodeList(raw);
    } catch (e) {
      debugPrint('[StorageService] loadTasks error: $e');
      return [];
    }
  }

  /// Persists the full task list atomically.
  static Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tasksKey, Task.encodeList(tasks));
    } catch (e) {
      debugPrint('[StorageService] saveTasks error: $e');
    }
  }
}
