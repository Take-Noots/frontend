import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/notification_manager.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int currentPage = 1;
  bool hasMorePages = true;
  String? currentUserId;
  Timer? _autoRefreshTimer;
  StreamSubscription? _notificationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadNotifications();
    _setupRealTimeNotifications();
    _startAutoRefresh();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'};
    setState(() {
      currentUserId = userData['id'];
    });
  }

  void _setupRealTimeNotifications() async {
    // Initialize notification manager for real-time updates
    await NotificationManager.instance.initialize();

    // Listen for new notifications and refresh the list
    _notificationStreamSubscription =
        NotificationManager.instance.notificationStream.listen((notification) {
      if (mounted) {
        _refreshNotifications();
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted && !_isLoading) {
        _refreshNotifications();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && hasMorePages) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      currentPage = 1;
      hasMorePages = true;
    });
    await _loadNotifications(refresh: true);
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    try {
      if (!refresh) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final result = await _notificationService.getUserNotifications(
        page: 1,
        limit: 20,
      );

      if (result['success']) {
        final responseData = result['data'];
        final List<dynamic> notificationsData = responseData['notifications'];
        final pagination = responseData['pagination'];

        final notificationList = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        setState(() {
          notifications = notificationList;
          currentPage = 1;
          hasMorePages = pagination['currentPage'] < pagination['totalPages'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _notificationService.getUserNotifications(
        page: currentPage + 1,
        limit: 20,
      );

      if (result['success']) {
        final responseData = result['data'];
        final List<dynamic> notificationsData = responseData['notifications'];
        final pagination = responseData['pagination'];

        final newNotifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        setState(() {
          notifications.addAll(newNotifications);
          currentPage = pagination['currentPage'];
          hasMorePages = pagination['currentPage'] < pagination['totalPages'];
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final result = await _notificationService.markAllAsRead();
      if (result['success']) {
        setState(() {
          notifications = notifications.map((notification) {
            return NotificationModel(
              id: notification.id,
              recipientId: notification.recipientId,
              senderId: notification.senderId,
              senderUsername: notification.senderUsername,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              data: notification.data,
              isRead: true,
              createdAt: notification.createdAt,
              updatedAt: DateTime.now(),
            );
          }).toList();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = NotificationModel(
            id: notification.id,
            recipientId: notification.recipientId,
            senderId: notification.senderId,
            senderUsername: notification.senderUsername,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            isRead: true,
            createdAt: notification.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      });
    }

    // Navigate based on notification type using go_router
    switch (notification.type) {
      case NotificationType.message:
        if (notification.data.chatId != null) {
          context.push('/chat/${notification.data.chatId}');
        }
        break;
      case NotificationType.groupMessage:
        if (notification.data.groupChatId != null && currentUserId != null) {
          context.push(
              '/group-chat/${notification.data.groupChatId}?currentUserId=$currentUserId');
        }
        break;
      case NotificationType.postLike:
      case NotificationType.postComment:
        if (notification.data.postId != null) {
          context.push('/post/${notification.data.postId}');
        }
        break;
      case NotificationType.fanbasePostLike:
      case NotificationType.fanbasePostComment:
        if (notification.data.fanbasePostId != null &&
            notification.data.fanbaseId != null) {
          context.push(
              '/fanbase-post/${notification.data.fanbasePostId}?fanbaseId=${notification.data.fanbaseId}');
        }
        break;
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Delete Notification',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result =
            await _notificationService.deleteNotification(notification.id);
        if (result['success']) {
          setState(() {
            notifications.removeWhere((n) => n.id == notification.id);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting notification: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadNotifications(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                color: Theme.of(context).colorScheme.onPrimary, size: 48),
            const SizedBox(height: 16),
            Text('No notifications yet',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18)),
            Text('We\'ll notify you when something happens!',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDelete: () => _deleteNotification(notification),
          );
        },
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.transparent
            : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.message:
      case NotificationType.groupMessage:
        return Colors.blue;
      case NotificationType.postLike:
      case NotificationType.fanbasePostLike:
        return Colors.red;
      case NotificationType.postComment:
      case NotificationType.fanbasePostComment:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.groupMessage:
        return Icons.group;
      case NotificationType.postLike:
      case NotificationType.fanbasePostLike:
        return Icons.favorite;
      case NotificationType.postComment:
      case NotificationType.fanbasePostComment:
        return Icons.comment;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
