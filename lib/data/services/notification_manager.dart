// lib/data/services/notification_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../helpers/notification_helper.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class NotificationManager {
  static NotificationManager? _instance;
  static NotificationManager get instance => _instance ??= NotificationManager._();
  
  NotificationManager._();

  IO.Socket? _socket;
  Timer? _pollTimer;
  final NotificationService _notificationService = NotificationService();
  
  String? _currentUserId;
  bool _isInitialized = false;
  
  // Stream controllers for real-time updates
  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<int> _unreadCountStreamController =
      StreamController<int>.broadcast();

  Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;
  Stream<int> get unreadCountStream => _unreadCountStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadCurrentUserId();
    if (_currentUserId == null) return;
    
    await NotificationHelper.init();
    await _initializeSocket();
    _startPolling();
    
    _isInitialized = true;
    print('✅ NotificationManager initialized for user: $_currentUserId');
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUserId = userData['id'];
      }
    } catch (e) {
      print('❌ Error loading user ID: $e');
    }
  }

  Future<void> _initializeSocket() async {
    if (_currentUserId == null) return;

    try {
      _socket = IO.io('http://localhost:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        print('🔌 Socket connected');
        _socket!.emit('join', _currentUserId);
      });

      _socket!.onDisconnect((_) {
        print('🔌 Socket disconnected');
      });

      // Listen for new notifications
      _socket!.on('new_notification', (data) {
        _handleNewNotification(data);
      });

      // Listen for message notifications
      _socket!.on('new_message', (data) {
        _handleMessageNotification(data);
      });

      // Listen for post like notifications
      _socket!.on('post_liked', (data) {
        _handlePostLikeNotification(data);
      });

      // Listen for comment notifications
      _socket!.on('post_commented', (data) {
        _handleCommentNotification(data);
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Socket connection error: $e');
      // Fallback to polling if socket fails
    }
  }

  void _handleNewNotification(dynamic data) {
    try {
      final notification = NotificationModel.fromJson(data);
      _notificationStreamController.add(notification);
      _updateUnreadCount();
      
      // Show local notification
      _showLocalNotification(notification);
    } catch (e) {
      print('❌ Error handling new notification: $e');
    }
  }

  void _handleMessageNotification(dynamic data) {
    final senderName = data['senderUsername'] ?? 'Someone';
    final message = data['messageText'] ?? '';
    final chatId = data['chatId'] ?? '';
    final isGroup = data['isGroup'] == true;
    final groupName = data['groupName'];

    if (kIsWeb) {
      print('📱 [WEB] New message from $senderName: $message');
    }

    NotificationHelper.showMessageNotification(
      senderName: senderName,
      message: message,
      chatId: chatId,
      isGroupMessage: isGroup,
      groupName: groupName,
    );
  }

  void _handlePostLikeNotification(dynamic data) {
    final senderName = data['senderUsername'] ?? 'Someone';
    final songName = data['songName'] ?? 'your post';
    final postId = data['postId'] ?? '';

    if (kIsWeb) {
      print('📱 [WEB] $senderName liked your post "$songName"');
    }

    NotificationHelper.showPostLikeNotification(
      senderName: senderName,
      songName: songName,
      postId: postId,
    );
  }

  void _handleCommentNotification(dynamic data) {
    final senderName = data['senderUsername'] ?? 'Someone';
    final songName = data['songName'] ?? 'your post';
    final comment = data['commentText'] ?? '';
    final postId = data['postId'] ?? '';

    if (kIsWeb) {
      print('📱 [WEB] $senderName commented on "$songName": $comment');
    }

    NotificationHelper.showPostCommentNotification(
      senderName: senderName,
      songName: songName,
      comment: comment,
      postId: postId,
    );
  }

  void _showLocalNotification(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.message:
        NotificationHelper.showMessageNotification(
          senderName: notification.senderUsername,
          message: notification.data.messageText ?? notification.message,
          chatId: notification.data.chatId ?? '',
        );
        break;
      case NotificationType.groupMessage:
        NotificationHelper.showMessageNotification(
          senderName: notification.senderUsername,
          message: notification.data.messageText ?? notification.message,
          chatId: notification.data.groupChatId ?? '',
          isGroupMessage: true,
          groupName: notification.data.groupName,
        );
        break;
      case NotificationType.postLike:
        NotificationHelper.showPostLikeNotification(
          senderName: notification.senderUsername,
          songName: notification.data.songName ?? 'your post',
          postId: notification.data.postId ?? '',
        );
        break;
      case NotificationType.postComment:
        NotificationHelper.showPostCommentNotification(
          senderName: notification.senderUsername,
          songName: notification.data.songName ?? 'your post',
          comment: notification.data.commentText ?? '',
          postId: notification.data.postId ?? '',
        );
        break;
      default:
        break;
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateUnreadCount();
    });
  }

  Future<void> _updateUnreadCount() async {
    try {
      final result = await _notificationService.getUnreadCount();
      if (result['success']) {
        final count = result['data']['unreadCount'] ?? 0;
        _unreadCountStreamController.add(count);
      }
    } catch (e) {
      print('❌ Error updating unread count: $e');
    }
  }

  // Manual refresh method
  Future<void> refreshNotifications() async {
    await _updateUnreadCount();
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _pollTimer?.cancel();
    _notificationStreamController.close();
    _unreadCountStreamController.close();
    _isInitialized = false;
  }
}