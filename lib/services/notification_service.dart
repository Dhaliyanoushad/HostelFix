import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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

  /// Send notification to a specific user via Firestore
  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'data': data,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Listen for new notifications in Firestore for the current user
  static void listenToNotifications(String uid) {
    if (uid.isEmpty) return;
    
    // Removing orderBy to avoid index requirement for simple cross-device notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // Show local notification
          showNotification(
            title: data['title'] ?? 'Notification',
            body: data['body'] ?? '',
          );

          // Mark as read so it doesn't trigger again
          change.doc.reference.update({'read': true});
        }
      }
    }, onError: (e) {
      debugPrint("Notification Listener Error: $e");
    });
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
