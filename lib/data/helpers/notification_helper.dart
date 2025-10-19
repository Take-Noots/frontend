import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:universal_html/html.dart' as html;

// Only import these if not on web
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'notification_helper_web_stub.dart';
import 'package:permission_handler/permission_handler.dart'
    if (dart.library.html) 'notification_helper_web_stub.dart';
import 'dart:io' if (dart.library.html) 'notification_helper_web_stub.dart';

class NotificationHelper {
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _initialized = false;
  static bool _webNotificationsEnabled = false;

  static Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      await _initWebNotifications();
    } else {
      await _initMobileNotifications();
    }

    _initialized = true;
  }

  static Future<void> _initWebNotifications() async {
    try {
      // Check if the browser supports notifications
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        _webNotificationsEnabled = permission == 'granted';

        if (_webNotificationsEnabled) {
          print('✅ Web notifications enabled');
        } else {
          print(
              '⚠️ Web notifications permission denied, falling back to console logs');
        }
      } else {
        print(
            '⚠️ Web notifications not supported, falling back to console logs');
      }
    } catch (e) {
      print('❌ Error initializing web notifications: $e');
    }
  }

  static Future<void> _initMobileNotifications() async {
    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('✅ Mobile notifications initialized successfully');
    } catch (e) {
      print('❌ Error initializing mobile notifications: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    try {
      if (!kIsWeb) {
        // Check if we're on Android
        if (defaultTargetPlatform == TargetPlatform.android) {
          await Permission.notification.request();
        }

        // Check if we're on iOS
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await _notificationsPlugin
              ?.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              );
        }
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatId,
    bool isGroupMessage = false,
    String? groupName,
  }) async {
    final title = isGroupMessage
        ? (groupName ?? 'Group Message')
        : 'Message from $senderName';

    final body = isGroupMessage ? '$senderName: $message' : message;

    if (kIsWeb) {
      await _showWebNotification(
        title: title,
        body: body,
        icon: '💬',
        onClick: () => _handleNotificationClick('message', {'chatId': chatId}),
      );
      return;
    }

    await init();
    if (_notificationsPlugin == null) return;

    final payload = jsonEncode({
      'type': isGroupMessage ? 'group_message' : 'message',
      'chatId': chatId,
      'senderId': senderName,
    });

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'messages',
      channelName: 'Messages',
      channelDescription: 'New message notifications',
    );
  }

  static Future<void> showPostLikeNotification({
    required String senderName,
    required String songName,
    required String postId,
  }) async {
    const title = 'Post Liked';
    final body = '$senderName liked your post "$songName"';

    if (kIsWeb) {
      await _showWebNotification(
        title: title,
        body: body,
        icon: '❤️',
        onClick: () =>
            _handleNotificationClick('post_like', {'postId': postId}),
      );
      return;
    }

    await init();
    if (_notificationsPlugin == null) return;

    final payload = jsonEncode({
      'type': 'post_like',
      'postId': postId,
      'senderId': senderName,
    });

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'likes',
      channelName: 'Likes',
      channelDescription: 'Post like notifications',
    );
  }

  static Future<void> showPostCommentNotification({
    required String senderName,
    required String songName,
    required String comment,
    required String postId,
  }) async {
    const title = 'New Comment';
    final body = '$senderName commented on "$songName": $comment';

    if (kIsWeb) {
      await _showWebNotification(
        title: title,
        body: body,
        icon: '💬',
        onClick: () =>
            _handleNotificationClick('post_comment', {'postId': postId}),
      );
      return;
    }

    await init();
    if (_notificationsPlugin == null) return;

    final payload = jsonEncode({
      'type': 'post_comment',
      'postId': postId,
      'senderId': senderName,
    });

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'comments',
      channelName: 'Comments',
      channelDescription: 'Post comment notifications',
    );
  }

  static Future<void> showFanbaseNotification({
    required String senderName,
    required String fanbaseName,
    required String postTopic,
    required String fanbasePostId,
    required bool isLike,
    String? comment,
  }) async {
    final title = isLike ? 'Fanbase Post Liked' : 'New Fanbase Comment';
    final body = isLike
        ? '$senderName liked your post "$postTopic" in $fanbaseName'
        : '$senderName commented on "$postTopic" in $fanbaseName: ${comment ?? ''}';

    if (kIsWeb) {
      await _showWebNotification(
        title: title,
        body: body,
        icon: isLike ? '❤️' : '💬',
        onClick: () => _handleNotificationClick(
            isLike ? 'fanbase_post_like' : 'fanbase_post_comment',
            {'fanbasePostId': fanbasePostId}),
      );
      return;
    }

    await init();
    if (_notificationsPlugin == null) return;

    final payload = jsonEncode({
      'type': isLike ? 'fanbase_post_like' : 'fanbase_post_comment',
      'fanbasePostId': fanbasePostId,
      'senderId': senderName,
    });

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'fanbase',
      channelName: 'Fanbase',
      channelDescription: 'Fanbase activity notifications',
    );
  }

  static Future<void> _showWebNotification({
    required String title,
    required String body,
    String? icon,
    VoidCallback? onClick,
  }) async {
    // Enhanced console logging for web
    final timestamp = DateTime.now().toString().substring(11, 19);
    print('🌐 [$timestamp] ${icon ?? '🔔'} $title');
    print('   └─ $body');
    print('   └─ Click to navigate (simulated)');

    if (onClick != null) {
      print('   └─ Navigation action would be triggered');
    }

    // If browser notifications are available and permitted
    if (kIsWeb && _webNotificationsEnabled) {
      try {
        final notification = html.Notification(title,
            body: body, icon: '/icons/noot-icon-192.png');

        notification.onClick.listen((event) {
          notification.close();
          onClick?.call();
        });

        // Auto-close after 5 seconds
        Timer(const Duration(seconds: 5), () {
          notification.close();
        });
      } catch (e) {
        print('❌ Browser notification error: $e');
      }
    }
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    if (kIsWeb || _notificationsPlugin == null) return;

    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF1DB954), // Spotify green
        enableLights: true,
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(body),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin!.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  static void _handleNotificationClick(String type, Map<String, dynamic> data) {
    print('🔔 Notification clicked: $type');
    print('   Data: $data');

    // Here you could emit events or call navigation methods
    // For example, you could use a global navigation service
  }

  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        print(
            '🔔 Mobile notification tapped: ${data['type']} from ${data['senderId']}');
        _handleNotificationClick(data['type'], data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }
}
