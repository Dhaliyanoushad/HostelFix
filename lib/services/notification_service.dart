import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? channelId,
    String? channelName,
    Color? color,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId ?? 'general_notifications',
      channelName ?? 'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      color: color ?? const Color(0xFF2563EB),
      playSound: true,
      enableVibration: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      details,
    );
  }

  static Future<void> showEmergencyNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'emergency_channel',
      channelName: 'Emergency Complaints',
      color: const Color(0xFFFF0000),
    );
  }
}
