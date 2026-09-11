import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _currentMemberId;
  String? _currentMemberNo;
  StreamSubscription? _notifSubscription;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permissions for Android 13+
    if (!kIsWeb) {
      final androidImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }

    _isInitialized = true;
  }

    void startListening(String memberId, String memberNo) {
    debugPrint("=== NOTIFICATION_DEBUG: startListening called. memberId: $memberId, memberNo: $memberNo ===");
    if (memberId.isEmpty || memberId == 'N/A' || memberId == 'null') { debugPrint("=== NOTIFICATION_DEBUG: Ignored because memberId is invalid ==="); return; }
    if (_currentMemberId == memberId && _currentMemberNo == memberNo && _notifSubscription != null) { debugPrint("=== NOTIFICATION_DEBUG: Ignored because already listening to these IDs ==="); return; }
    
    _currentMemberId = memberId;
    _currentMemberNo = memberNo;
    
    _notifSubscription?.cancel();
    debugPrint("=== NOTIFICATION_DEBUG: Attached Firestore listener for notifications ===");
    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      debugPrint("=== NOTIFICATION_DEBUG: Snapshot received with ${snapshot.docChanges.length} changes ===");
      for (var change in snapshot.docChanges) {
        // Only trigger for newly added documents while listening
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          // Check target
          final targetType = data['targetType'];
          final targetMembers = data['targetMembers'] as List<dynamic>? ?? [];
          debugPrint("=== NOTIFICATION_DEBUG: Received Notification '${data['title']}', targetType: $targetType, targetMembers: $targetMembers ===");

          if (targetType == 'all' || (targetType == 'specific' && (targetMembers.contains(memberId) || targetMembers.contains(memberNo)))) {
            debugPrint("=== NOTIFICATION_DEBUG: Notification MATCHED member IDs! ===");
          }
          if (targetType == 'all' ||
              (targetType == 'specific' && (targetMembers.contains(memberId) || targetMembers.contains(memberNo)))) {
            final scheduledAt = data['scheduledAt'] as Timestamp?;
            final now = DateTime.now();

            if (scheduledAt == null ||
                scheduledAt.toDate().isBefore(now) ||
                scheduledAt.toDate().isAtSameMomentAs(now)) {
              final createdAt = data['createdAt'] as Timestamp?;
              if (createdAt != null) {
                final timeToCompare = scheduledAt ?? createdAt;
                debugPrint(
                    "🔔 New Notification Detected: ${data['title']} (Time diff: ${now.difference(timeToCompare.toDate()).inMinutes}m)");
                if (now.difference(timeToCompare.toDate()).inMinutes < 5) {
                  debugPrint("🔔 Triggering Local Notification!");
                  _showNotification(
                    id: change.doc.id.hashCode,
                    title: data['title'] ?? 'New Notification',
                    body: data['body'] ?? '',
                  );
                } else {
                  debugPrint("🔕 Notification too old to pop up.");
                }
              }
            }
          }
        }
      }
    });
  }

  Future<void> _showNotification(
      {required int id, required String title, required String body}) async {
    if (kIsWeb)
      return; // local notifications don't work on web easily without service workers

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'aiaprtd_notifications', // unique id
      'High Importance Notifications',
      channelDescription: 'Used for important alerts from Admin',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      enableLights: true,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
