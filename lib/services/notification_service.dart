// lib/services/notification_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

/// Handles all native notification logic:
///   • Initialisation with timezone setup
///   • Runtime permission requests (Android 13+ / iOS)
///   • Scheduling exact notifications at task deadlines
///   • Cancelling notifications when tasks are deleted / completed
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized     = false;
  static bool _permGranted     = false;

  static bool get permissionGranted => _permGranted;

  // ── Notification channel / details ────────────────────────────────────────

  static const String _channelId   = 'lumina_channel_v1';
  static const String _channelName = 'Lumina Reminders';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Task deadline reminders from Lumina',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Must be called in main() before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    // Set up timezone data + local timezone
    tz_data.initializeTimeZones();
    try {
      final String name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // we request manually below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  /// Requests notification permissions at runtime.
  /// Returns true if granted.
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        _permGranted = (await impl?.requestNotificationsPermission()) ?? false;
      } else if (!kIsWeb && Platform.isIOS) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        _permGranted = (await impl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            false;
      } else {
        _permGranted = true; // Web / Desktop: assume granted
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermissions error: $e');
      _permGranted = false;
    }
    return _permGranted;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Schedules a native notification at [task.deadline].
  /// Silently skips if deadline is null, already passed, or permission denied.
  static Future<void> scheduleForTask(Task task) async {
    if (!_permGranted || task.deadline == null) return;

    final scheduled = tz.TZDateTime.from(task.deadline!, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        _notifId(task.id),
        '✦ Lumina Reminders',
        task.text,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleForTask error: $e');
    }
  }

  /// Cancels a previously scheduled notification for this task.
  static Future<void> cancelForTask(String taskId) async {
    await _plugin.cancel(_notifId(taskId));
  }

  /// Fires an immediate notification (used for overdue tasks when app is open).
  static Future<void> showNow(Task task) async {
    if (!_permGranted) return;
    await _plugin.show(
      _notifId(task.id),
      '✦ Lumina Reminders',
      task.text,
      _details,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps a UUID string to a stable int notification ID.
  static int _notifId(String taskId) =>
      taskId.hashCode.abs() % 2147483647;
}