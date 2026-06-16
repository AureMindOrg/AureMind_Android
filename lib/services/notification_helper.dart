import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      // Set a fallback timezone location to completely prevent TZ crashes
      tz.setLocalLocation(tz.getLocation('UTC'));
      
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings settings = InitializationSettings(android: androidSettings);
      
      await _notificationsPlugin.initialize(settings);
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  static Future<void> scheduleTaskNotification(int id, String title, DateTime scheduledTime) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) return; 

      await _notificationsPlugin.zonedSchedule(
        id,
        'Task Reminder',
        title,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for upcoming tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Catching the error ensures the app DOES NOT crash if scheduling fails
      debugPrint("Failed to schedule notification: $e");
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint("Failed to cancel notification: $e");
    }
  }
}