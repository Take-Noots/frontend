// lib/core/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_manager.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotificationProvider() {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Listen to new notifications
    NotificationManager.instance.notificationStream.listen((notification) {
      _notifications.insert(0, notification);
      notifyListeners();
    });

    // Listen to unread count changes
    NotificationManager.instance.unreadCountStream.listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setNotifications(List<NotificationModel> notifications) {
    _notifications = notifications;
    notifyListeners();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}