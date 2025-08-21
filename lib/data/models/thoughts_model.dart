class ThoughtsPost {
  final String id;
  final String userId;
  final String? username;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  int likes;
  List<String> likedBy;
  List<ThoughtsComment> comments;
  String? songName;
  String? artistName;
  String? coverImage;
  final int isHidden; // 0 = visible, 1 = hidden
  final int isDeleted; // 0 = not deleted, 1 = deleted

  ThoughtsPost({
    required this.id,
    required this.userId,
    this.username,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.likedBy,
    required this.comments,
    this.songName,
    this.artistName,
    this.coverImage,
    required this.isHidden,
    required this.isDeleted,
  });

  factory ThoughtsPost.fromJson(Map<String, dynamic> json) {
  return ThoughtsPost(
    id: json['_id'] ?? '',
    userId: json['userId'] ?? '',
    username: json['username'],
    text: json['text'] ?? json['thoughtsText'] ?? '',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    likes: json['likes'] ?? 0,
    likedBy: List<String>.from(json['likedBy'] ?? []),
    comments: (json['comments'] as List<dynamic>?)
        ?.map((c) => ThoughtsComment.fromJson(c))
        .toList() ?? [],
    songName: json['songName'],
    artistName: json['artistName'],
    coverImage: json['coverImage'],
    isHidden: _parseIsHidden(json['isHidden']),
    isDeleted: _parseIsDeleted(json['isDeleted']),
  );
}

  // Helper method to parse isHidden field from various types
  static int _parseIsHidden(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1' ? 1 : 0;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    return 0;
  }

  // Helper method to parse isDeleted field from various types
  static int _parseIsDeleted(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1' ? 1 : 0;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'username': username,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments.map((c) => c.toJson()).toList(),
      'songName': songName,
      'artistName': artistName,
      'coverImage': coverImage,
      'isHidden': isHidden,
      'isDeleted': isDeleted,
    };
  }
}

class ThoughtsComment {
  final String id;
  final String userId;
  final String? username;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  int likes;
  List<String> likedBy;

  ThoughtsComment({
    required this.id,
    required this.userId,
    this.username,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.likedBy,
  });

  factory ThoughtsComment.fromJson(Map<String, dynamic> json) {
    return ThoughtsComment(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'],
      text: json['thoughtsText'] ?? json['text'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'likes': likes,
      'likedBy': likedBy,
    };
  }
}
