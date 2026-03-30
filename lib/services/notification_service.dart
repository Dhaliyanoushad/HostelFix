import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

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

    // Request permissions for Android 13+ local notifications
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Firebase Messaging Initialization
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Listen to foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  /// Ensure we save the token for the currently logged in user
  static Future<void> saveTokenToDatabase(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && uid.isNotEmpty) {
        // We find the user document by searching for uid
        QuerySnapshot snap = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update({'fcmToken': token});
        }
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  /// Get OAuth2 Access token from the service account JSON
  static Future<String> _getAccessToken() async {
    try {
      final String serviceAccountJson =
          await rootBundle.loadString('assets/service_account.json');
      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      debugPrint("Error: Could not load service_account.json for FCM. $e");
      return '';
    }
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

  /// Send notification to a specific user via Firestore and FCM API
  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // 1. Keep the Firestore logging for in-app history
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'data': data,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Fetch the recipient's FCM token
    try {
      QuerySnapshot userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: recipientId)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) return;

      var userData = userSnap.docs.first.data() as Map<String, dynamic>;
      if (!userData.containsKey('fcmToken') || userData['fcmToken'] == null) {
        return;
      }

      final String fcmToken = userData['fcmToken'];

      // 3. Send via FCM HTTP v1 using Service Account
      final String serverToken = await _getAccessToken();
      if (serverToken.isEmpty) {
        debugPrint(
            "FCM Missing Access Token. Ensure assets/service_account.json exists.");
        return;
      }

      // Extract Project ID from service account JSON
      final String serviceAccountJson =
          await rootBundle.loadString('assets/service_account.json');
      final Map<String, dynamic> saMap = jsonDecode(serviceAccountJson);
      final String projectId = saMap['project_id'];

      final String endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode != 200) {
        debugPrint("FCM Send Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("FCM Send Exception: $e");
    }
  }

  /// Listener for foreground notifications (now mostly kept for in-app messaging history if needed)
  static void listenToNotifications(String uid) {
    // We can keep this if the app needs to process Firestore notifications dynamically.
    // However, we remove showNotification() here because FCM handles it.
    if (uid.isEmpty) return;
    
    FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // Just mark as read if you don't use this as an unread inbox.
          // Otherwise you keep it as is. Let's just update read to true.
          change.doc.reference.update({'read': true});
        }
      }
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
