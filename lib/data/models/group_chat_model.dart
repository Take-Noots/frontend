class GroupChatUser {
  final String id;
  final String username;
  final String? profileImage;
  final bool isOnline;
  final String lastSeen;

  GroupChatUser({
    required this.id,
    required this.username,
    this.profileImage,
    required this.isOnline,
    required this.lastSeen,
  });

  factory GroupChatUser.fromJson(Map<String, dynamic> json) {
    return GroupChatUser(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? 'Unknown User',
      profileImage: json['profileImage'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] ?? 'Unknown',
    );
  }
}

class GroupMessage {
  final String id;
  final String senderId;
  final String senderUsername;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return GroupMessage(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderUsername: json['senderUsername'] ?? 'Unknown',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isMe: json['senderId'] == currentUserId,
    );
  }
}

class GroupChat {
  final String id;
  final String name;
  final String? description;
  final String? groupIcon;
  final List<GroupChatUser> members;
  final GroupMessage? lastMessage;
  final String createdBy;
  final DateTime createdAt;
  final int unreadCount;

  GroupChat({
    required this.id,
    required this.name,
    this.description,
    this.groupIcon,
    required this.members,
    this.lastMessage,
    required this.createdBy,
    required this.createdAt,
    this.unreadCount = 0,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json, String currentUserId) {
    final membersData = json['members'] as List<dynamic>? ?? [];
    final members = membersData.map((member) => GroupChatUser.fromJson(member)).toList();

    return GroupChat(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Group',
      description: json['description'],
      groupIcon: json['groupIcon'],
      members: members,
      lastMessage: json['lastMessage'] != null 
          ? GroupMessage.fromJson(json['lastMessage'], currentUserId)
          : null,
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}