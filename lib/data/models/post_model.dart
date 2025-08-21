class Comment {
  final String id;
  final String userId;
  final String? username;
  final String text;
  final DateTime createdAt;
  int likes;
  List<String> likedBy;

  Comment({
    required this.id,
    required this.userId,
    this.username,
    required this.text,
    required this.createdAt,
    required this.likes,
    required this.likedBy,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['_id'] ?? '',
        userId: json['userId'] ?? '',
        username: json['username'],
        text: json['text'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        likes: json['likes'] ?? 0,
        likedBy: List<String>.from(json['likedBy'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        '_id': id,
        'userId': userId,
        'username': username,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'likedBy': likedBy,
      };
}

class Post {
  final int isHidden; // 0 = visible, 1 = hidden
  final int isDeleted; // 0 = not deleted, 1 = deleted
  final String id;
  final String trackId;
  final String songName;
  final String artists;
  final String? albumImage;
  final String? caption;
  final String? userId; 
  final String? username;
  int likes;
  int commentsCount;
  List<String> likedBy;
  bool likedByMe;
  bool isSaved; 
  final DateTime createdAt;
  final DateTime updatedAt;
  List<Comment> comments;

  Post({
    required this.id,
    required this.isHidden,
    required this.isDeleted,
    required this.trackId,
    required this.songName,
    required this.artists,
    this.albumImage,
    this.caption,
    this.userId,
    this.username,
    required this.likes,
    required this.commentsCount,
    required this.likedBy,
    required this.likedByMe,
    this.isSaved = false,
    required this.createdAt,
    required this.updatedAt,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      isHidden: _parseIsHidden(json['isHidden']),
      isDeleted: _parseIsDeleted(json['isDeleted']),
      trackId: json['trackId'] ?? '',
      songName: json['songName'] ?? '',
      artists: json['artists'] ?? '',
      albumImage: json['albumImage'],
      caption: json['caption'],
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      likes: json['likes'] ?? 0,
      commentsCount: json['comments'] is int
          ? json['comments']
          : (json['comments'] as List).length,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likedByMe: false,
      isSaved: _parseIsSaved(json['isSaved']),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      comments: (json['comments'] is List)
          ? (json['comments'] as List)
              .map((c) => Comment.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // Helper method to parse isSaved field from various types
  static bool _parseIsSaved(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value == 1;
    }
    return false;
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
      'isHidden': isHidden,
      'isDeleted': isDeleted,
      'trackId': trackId,
      'songName': songName,
      'artists': artists,
      'albumImage': albumImage,
      'caption': caption,
      'userId': userId,
      'username': username,
      'likes': likes,
      'comments': comments.map((c) => c.toJson()).toList(),
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'isSaved': isSaved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

  }

  Post copyWith({
    String? id,
    int? isHidden,
    int? isDeleted,
    String? trackId,
    String? songName,
    String? artists,
    String? albumImage,
    String? caption,
    String? userId,
    String? username,
    int? likes,
    int? commentsCount,
    List<String>? likedBy,
    bool? likedByMe,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      isHidden: isHidden ?? this.isHidden,
      isDeleted: isDeleted ?? this.isDeleted,
      trackId: trackId ?? this.trackId,
      songName: songName ?? this.songName,
      artists: artists ?? this.artists,
      albumImage: albumImage ?? this.albumImage,
      caption: caption ?? this.caption,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      likedByMe: likedByMe ?? this.likedByMe,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
    );
  }
}
