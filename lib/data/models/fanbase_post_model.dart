class FanbasePostComment {
  final String userId;
  final String userName;
  final String comment;
  final int likeCount;
  final List<String> likeUserIds;
  final DateTime createdAt;

  FanbasePostComment({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.likeCount,
    required this.likeUserIds,
    required this.createdAt,
  });

  factory FanbasePostComment.fromJson(Map<String, dynamic> json) {
    return FanbasePostComment(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      comment: json['comment'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      likeUserIds: List<String>.from(json['likeUserIds'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'likeCount': likeCount,
      'likeUserIds': likeUserIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FanbasePost {
  final String id;
  final Map<String, String> createdBy;
  final String topic;
  final String description;
  final String? spotifyTrackId;
  final String? songName;
  final String? artistName;
  final String? albumArt;
  final int likesCount;
  final List<String> likeUserIds;
  final int commentsCount;
  final List<FanbasePostComment> comments;
  final String fanbaseId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLiked;

  FanbasePost({
    required this.id,
    required this.createdBy,
    required this.topic,
    required this.description,
    this.spotifyTrackId,
    this.songName,
    this.artistName,
    this.albumArt,
    required this.likesCount,
    required this.likeUserIds,
    required this.commentsCount,
    required this.comments,
    required this.fanbaseId,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
  });

  factory FanbasePost.fromJson(Map<String, dynamic> json) {
    return FanbasePost(
      id: json['_id'] ?? '',
      createdBy: Map<String, String>.from(json['createdBy'] ?? {}),
      topic: json['topic'] ?? '',
      description: json['description'] ?? '',
      spotifyTrackId: json['spotifyTrackId'],
      songName: json['songName'],
      artistName: json['artistName'],
      albumArt: json['albumArt'],
      likesCount: json['likesCount'] ?? 0,
      likeUserIds: List<String>.from(json['likeUserIds'] ?? []),
      commentsCount: json['commentsCount'] ?? 0,
      comments: (json['comments'] as List<dynamic>?)
              ?.map(
                  (c) => FanbasePostComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      fanbaseId: json['fanbaseId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'createdBy': createdBy,
      'topic': topic,
      'description': description,
      if (spotifyTrackId != null) 'spotifyTrackId': spotifyTrackId,
      if (songName != null) 'songName': songName,
      if (artistName != null) 'artistName': artistName,
      if (albumArt != null) 'albumArt': albumArt,
      'likesCount': likesCount,
      'likeUserIds': likeUserIds,
      'commentsCount': commentsCount,
      'comments': comments.map((c) => c.toJson()).toList(),
      'fanbaseId': fanbaseId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLiked': isLiked,
    };
  }

  FanbasePost copyWith({
    String? id,
    Map<String, String>? createdBy,
    String? topic,
    String? description,
    String? spotifyTrackId,
    String? songName,
    String? artistName,
    String? albumArt,
    int? likesCount,
    List<String>? likeUserIds,
    int? commentsCount,
    List<FanbasePostComment>? comments,
    String? fanbaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
  }) {
    return FanbasePost(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      spotifyTrackId: spotifyTrackId ?? this.spotifyTrackId,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      albumArt: albumArt ?? this.albumArt,
      likesCount: likesCount ?? this.likesCount,
      likeUserIds: likeUserIds ?? this.likeUserIds,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      fanbaseId: fanbaseId ?? this.fanbaseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
