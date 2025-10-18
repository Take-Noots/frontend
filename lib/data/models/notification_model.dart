enum NotificationType {
  message,
  groupMessage,
  postLike,
  postComment,
  fanbasePostLike,
  fanbasePostComment,
}

class NotificationData {
  final String? chatId;
  final String? groupChatId;
  final String? messageText;
  final String? postId;
  final String? postCaption;
  final String? songName;
  final String? artistName;
  final String? fanbasePostId;
  final String? fanbaseId;
  final String? fanbaseName;
  final String? postTopic;
  final String? commentText;
  final String? groupName;

  NotificationData({
    this.chatId,
    this.groupChatId,
    this.messageText,
    this.postId,
    this.postCaption,
    this.songName,
    this.artistName,
    this.fanbasePostId,
    this.fanbaseId,
    this.fanbaseName,
    this.postTopic,
    this.commentText,
    this.groupName,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      chatId: json['chatId'],
      groupChatId: json['groupChatId'],
      messageText: json['messageText'],
      postId: json['postId'],
      postCaption: json['postCaption'],
      songName: json['songName'],
      artistName: json['artistName'],
      fanbasePostId: json['fanbasePostId'],
      fanbaseId: json['fanbaseId'],
      fanbaseName: json['fanbaseName'],
      postTopic: json['postTopic'],
      commentText: json['commentText'],
      groupName: json['groupName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'groupChatId': groupChatId,
      'messageText': messageText,
      'postId': postId,
      'postCaption': postCaption,
      'songName': songName,
      'artistName': artistName,
      'fanbasePostId': fanbasePostId,
      'fanbaseId': fanbaseId,
      'fanbaseName': fanbaseName,
      'postTopic': postTopic,
      'commentText': commentText,
      'groupName': groupName,
    };
  }
}

class NotificationSender {
  final String id;
  final String username;
  final String? profileImage;

  NotificationSender({
    required this.id,
    required this.username,
    this.profileImage,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? 'Unknown User',
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'profileImage': profileImage,
    };
  }
}

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderUsername;
  final NotificationSender? sender;
  final NotificationType type;
  final String title;
  final String message;
  final NotificationData data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderUsername,
    this.sender,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      recipientId: json['recipientId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderUsername: json['senderUsername'] ?? 'Unknown',
      sender: json['senderId'] is Map<String, dynamic> 
          ? NotificationSender.fromJson(json['senderId']) 
          : null,
      type: _getNotificationTypeFromString(json['type'] ?? ''),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: NotificationData.fromJson(json['data'] ?? {}),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'recipientId': recipientId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'sender': sender?.toJson(),
      'type': _getNotificationTypeString(type),
      'title': title,
      'message': message,
      'data': data.toJson(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static NotificationType _getNotificationTypeFromString(String type) {
    switch (type) {
      case 'message':
        return NotificationType.message;
      case 'group_message':
        return NotificationType.groupMessage;
      case 'post_like':
        return NotificationType.postLike;
      case 'post_comment':
        return NotificationType.postComment;
      case 'fanbase_post_like':
        return NotificationType.fanbasePostLike;
      case 'fanbase_post_comment':
        return NotificationType.fanbasePostComment;
      default:
        return NotificationType.message;
    }
  }

  static String _getNotificationTypeString(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'message';
      case NotificationType.groupMessage:
        return 'group_message';
      case NotificationType.postLike:
        return 'post_like';
      case NotificationType.postComment:
        return 'post_comment';
      case NotificationType.fanbasePostLike:
        return 'fanbase_post_like';
      case NotificationType.fanbasePostComment:
        return 'fanbase_post_comment';
    }
  }

  String getTypeDisplayName() {
    switch (type) {
      case NotificationType.message:
        return 'Message';
      case NotificationType.groupMessage:
        return 'Group Message';
      case NotificationType.postLike:
        return 'Post Like';
      case NotificationType.postComment:
        return 'Comment';
      case NotificationType.fanbasePostLike:
        return 'Fanbase Like';
      case NotificationType.fanbasePostComment:
        return 'Fanbase Comment';
    }
  }

  String getIconName() {
    switch (type) {
      case NotificationType.message:
        return 'message';
      case NotificationType.groupMessage:
        return 'group';
      case NotificationType.postLike:
        return 'favorite';
      case NotificationType.postComment:
        return 'comment';
      case NotificationType.fanbasePostLike:
        return 'favorite';
      case NotificationType.fanbasePostComment:
        return 'comment';
    }
  }

  // Helper method to get the profile image URL
  String? getSenderProfileImage() {
    return sender?.profileImage;
  }

  // Helper method to get formatted time
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Helper method to check if notification is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // Helper method to get truncated message for display
  String getTruncatedMessage({int maxLength = 100}) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }

  // Create a copy of the notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? senderUsername,
    NotificationSender? sender,
    NotificationType? type,
    String? title,
    String? message,
    NotificationData? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel{id: $id, type: $type, title: $title, isRead: $isRead, createdAt: $createdAt}';
  }
}