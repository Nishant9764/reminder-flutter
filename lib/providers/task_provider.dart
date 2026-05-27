// lib/providers/task_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

// ── Toast data ────────────────────────────────────────────────────────────────

/// Lightweight struct passed to the Toast widget.
class ToastData {
  final String message;
  final String type; // 'info' | 'success' | 'warning' | 'error'
  const ToastData({required this.message, required this.type});
}

// ── TaskProvider ──────────────────────────────────────────────────────────────

/// Central state store for the app.
///
/// Responsibilities:
///   • Load / persist tasks via [StorageService]
///   • CRUD operations with immutable update patterns
///   • Schedule / cancel native notifications via [NotificationService]
///   • Poll every 60 s for overdue tasks → in-app toast fallback
///   • Expose toast state for the overlay
class TaskProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _notifGranted = false;
  bool _loading = true;
  Timer? _pollTimer;
  Timer? _toastTimer;
  ToastData? _currentToast;

  /// IDs that have already triggered an alert this session (prevents re-fire).
  final Set<String> _alerted = {};

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get activeTasks => _tasks.where((t) => !t.completed).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.completed).toList();
  bool get notifGranted => _notifGranted;
  bool get loading => _loading;
  ToastData? get currentToast => _currentToast;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Called once in main() after the provider is created.
  Future<void> init() async {
    _tasks = await StorageService.loadTasks();
    _notifGranted = await NotificationService.requestPermissions();
    _loading = false;
    notifyListeners();
    _startPolling();
  }

  // ── Polling: minute-by-minute deadline checker ─────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _checkDeadlines();
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkDeadlines();
    });
  }

  void _checkDeadlines() {
    final now = DateTime.now();
    final nowMin = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    for (final task in _tasks) {
      if (task.completed || task.deadline == null) continue;
      if (_alerted.contains(task.id)) continue;

      final d = task.deadline!;
      final dMin = DateTime(d.year, d.month, d.day, d.hour, d.minute);

      if (!nowMin.isBefore(dMin)) {
        _alerted.add(task.id);
        // Show in-app toast when native notification permission is denied
        if (!_notifGranted) {
          showToast('⏰  ${task.text}', 'info');
        }
      }
    }
  }

  // ── Toast helpers ──────────────────────────────────────────────────────────

  void showToast(String message, String type) {
    _toastTimer?.cancel();
    _currentToast = ToastData(message: message, type: type);
    notifyListeners();
    _toastTimer = Timer(const Duration(seconds: 5), dismissToast);
  }

  void dismissToast() {
    _currentToast = null;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  /// Adds a new task and schedules a notification if deadline is set.
  Future<void> addTask(String text, DateTime? deadline) async {
    final task = Task(
      id: _uuid.v4(),
      text: text,
      deadline: deadline,
      completed: false,
      createdAt: DateTime.now(),
    );

    // Immutable prepend
    _tasks = [task, ..._tasks];
    await _persist();
    notifyListeners();

    if (deadline != null) {
      await NotificationService.scheduleForTask(task);
    }
  }

  /// Toggles completed state.
  /// Cancels notification on completion; re-schedules on un-completion.
  Future<void> toggleTask(String id) async {
    _tasks = _tasks.map((t) {
      if (t.id != id) return t;
      final updated = t.copyWith(completed: !t.completed);
      if (updated.completed) {
        NotificationService.cancelForTask(id);
      } else if (updated.deadline != null) {
        NotificationService.scheduleForTask(updated);
      }
      return updated;
    }).toList();

    await _persist();
    notifyListeners();
  }

  /// Removes a task and cancels its scheduled notification.
  Future<void> deleteTask(String id) async {
    await NotificationService.cancelForTask(id);
    _tasks = _tasks.where((t) => t.id != id).toList();
    await _persist();
    notifyListeners();
  }

  /// Removes all completed tasks.
  Future<void> clearCompleted() async {
    for (final t in completedTasks) {
      await NotificationService.cancelForTask(t.id);
    }
    _tasks = activeTasks;
    await _persist();
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _persist() => StorageService.saveTasks(_tasks);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }
}
